#!/usr/bin/env python3
"""Windows-compatible trigger evaluation for a skill description.

Same contract as run_eval.py but uses subprocess.communicate(timeout=...)
instead of select.select on a pipe (which is broken on native Windows).
Trades off the early-detection optimization (~1-2s per query) for
portability.
"""

import argparse
import json
import os
import subprocess
import sys
import uuid
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

from scripts.utils import parse_skill_md


def find_project_root() -> Path:
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / ".claude").is_dir():
            return parent
    return current


def run_single_query(
    query: str,
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: str,
    model: str | None = None,
) -> tuple[bool, str]:
    """Run a single query and return (triggered, raw_output_preview).

    Creates a command file in .claude/commands/ so it appears in Claude's
    available_skills list, then runs `claude -p` to completion and inspects
    the assistant tool calls.
    """
    unique_id = uuid.uuid4().hex[:8]
    clean_name = f"{skill_name}-skill-{unique_id}"
    project_commands_dir = Path(project_root) / ".claude" / "commands"
    command_file = project_commands_dir / f"{clean_name}.md"

    try:
        project_commands_dir.mkdir(parents=True, exist_ok=True)
        indented_desc = "\n  ".join(skill_description.split("\n"))
        command_content = (
            f"---\n"
            f"description: |\n"
            f"  {indented_desc}\n"
            f"---\n\n"
            f"# {skill_name}\n\n"
            f"This skill handles: {skill_description}\n"
        )
        command_file.write_text(command_content, encoding="utf-8")

        cmd = [
            "claude",
            "-p", query,
            "--output-format", "stream-json",
            "--verbose",
        ]
        if model:
            cmd.extend(["--model", model])

        env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=False,
                cwd=project_root,
                env=env,
                timeout=timeout,
            )
        except subprocess.TimeoutExpired:
            return False, "TIMEOUT"

        stdout = result.stdout.decode("utf-8", errors="replace")

        triggered = False
        triggered_skill = None
        for line in stdout.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            if event.get("type") != "assistant":
                continue
            message = event.get("message", {})
            for content_item in message.get("content", []):
                if content_item.get("type") != "tool_use":
                    continue
                tool_name = content_item.get("name", "")
                tool_input = content_item.get("input", {})

                if tool_name == "Skill":
                    invoked = tool_input.get("skill", "")
                    if clean_name in invoked:
                        triggered = True
                        triggered_skill = invoked
                        break
                    elif invoked:
                        # Different skill was invoked — record for collision diagnostics
                        triggered_skill = invoked
                        break
                elif tool_name == "Read":
                    fp = tool_input.get("file_path", "")
                    if clean_name in fp:
                        triggered = True
                        triggered_skill = f"Read({fp})"
                        break

            if triggered_skill:
                break

        return triggered, triggered_skill or "no-skill-call"
    finally:
        if command_file.exists():
            command_file.unlink()


def run_eval(
    eval_set: list[dict],
    skill_name: str,
    description: str,
    num_workers: int,
    timeout: int,
    project_root: Path,
    runs_per_query: int = 1,
    trigger_threshold: float = 0.5,
    model: str | None = None,
) -> dict:
    results = []

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        future_to_info = {}
        for item in eval_set:
            for run_idx in range(runs_per_query):
                future = executor.submit(
                    run_single_query,
                    item["query"],
                    skill_name,
                    description,
                    timeout,
                    str(project_root),
                    model,
                )
                future_to_info[future] = (item, run_idx)

        query_triggers: dict[str, list[bool]] = {}
        query_collisions: dict[str, list[str]] = {}
        query_items: dict[str, dict] = {}
        for future in as_completed(future_to_info):
            item, _ = future_to_info[future]
            query = item["query"]
            query_items[query] = item
            query_triggers.setdefault(query, [])
            query_collisions.setdefault(query, [])
            try:
                triggered, collision_info = future.result()
                query_triggers[query].append(triggered)
                query_collisions[query].append(collision_info)
            except Exception as e:
                print(f"Warning: query failed: {e}", file=sys.stderr)
                query_triggers[query].append(False)
                query_collisions[query].append(f"ERROR: {e}")

    for query, triggers in query_triggers.items():
        item = query_items[query]
        trigger_rate = sum(triggers) / len(triggers)
        should_trigger = item["should_trigger"]
        if should_trigger:
            did_pass = trigger_rate >= trigger_threshold
        else:
            did_pass = trigger_rate < trigger_threshold
        results.append({
            "query": query,
            "category": item.get("category", ""),
            "should_trigger": should_trigger,
            "trigger_rate": trigger_rate,
            "triggers": sum(triggers),
            "runs": len(triggers),
            "pass": did_pass,
            "what_was_invoked": query_collisions[query],
        })

    passed = sum(1 for r in results if r["pass"])
    total = len(results)

    return {
        "skill_name": skill_name,
        "description": description,
        "results": results,
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Run trigger evaluation (Windows-compatible)")
    parser.add_argument("--eval-set", required=True)
    parser.add_argument("--skill-path", required=True)
    parser.add_argument("--description", default=None)
    parser.add_argument("--num-workers", type=int, default=4)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--runs-per-query", type=int, default=3)
    parser.add_argument("--trigger-threshold", type=float, default=0.5)
    parser.add_argument("--model", default=None)
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--output", default=None, help="Write JSON output to this path")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text(encoding="utf-8"))
    skill_path = Path(args.skill_path)

    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)

    name, original_description, _ = parse_skill_md(skill_path)
    description = args.description or original_description
    project_root = find_project_root()

    if args.verbose:
        print(f"Skill: {name}", file=sys.stderr)
        print(f"Eval set: {args.eval_set} ({len(eval_set)} queries × {args.runs_per_query} runs)", file=sys.stderr)

    output = run_eval(
        eval_set=eval_set,
        skill_name=name,
        description=description,
        num_workers=args.num_workers,
        timeout=args.timeout,
        project_root=project_root,
        runs_per_query=args.runs_per_query,
        trigger_threshold=args.trigger_threshold,
        model=args.model,
    )

    if args.verbose:
        summary = output["summary"]
        print(f"\nResults: {summary['passed']}/{summary['total']} passed\n", file=sys.stderr)
        for r in output["results"]:
            status = "PASS" if r["pass"] else "FAIL"
            rate = f"{r['triggers']}/{r['runs']}"
            cat = r.get("category", "")
            invoked = r.get("what_was_invoked", [])
            print(f"  [{status}] rate={rate} expected={r['should_trigger']} | {cat}", file=sys.stderr)
            print(f"         q: {r['query'][:90]}", file=sys.stderr)
            if not r["pass"]:
                print(f"         invoked: {invoked}", file=sys.stderr)

    json_out = json.dumps(output, indent=2)
    if args.output:
        Path(args.output).write_text(json_out, encoding="utf-8")
        if args.verbose:
            print(f"\nWrote results to {args.output}", file=sys.stderr)
    else:
        print(json_out)


if __name__ == "__main__":
    main()

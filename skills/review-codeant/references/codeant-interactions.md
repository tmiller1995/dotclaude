# CodeAnt AI Interaction Reference

Source: https://docs.codeant.ai/pull_request/howToUse

## Mention Handle

CodeAnt requires `@codeant-ai` in all replies to process them. Without this tag, CodeAnt will not see or act on the reply. Responses are typically processed within one minute.

## Command Formats

| Purpose | Syntax | Notes |
|---------|--------|-------|
| Re-trigger full review | `@codeant-ai: review` | Re-analyzes latest changes |
| Ask a question | `@codeant-ai ask: Your question here` | Works at PR level or inline on specific lines |
| Dispute a finding | `@codeant-ai: This is not an issue because [reasoning]` | CodeAnt learns from disputes and avoids similar flags in future reviews |

## Dispute / Dismiss Behavior

When you dispute a finding using `@codeant-ai: This is not an issue because [reasoning]`, CodeAnt:
- Creates a "learning" from the feedback
- Avoids similar flags in future reviews
- Learnings are manageable at `app.codeant.ai/settings/learnings`

This is the most important interaction for the review-codeant skill — every dismissed comment should use the dispute format so CodeAnt improves over time.

## Feedback Channel

The `@codeant-ai`-tagged reply is the real feedback channel. GitHub has no thread-status concept that CodeAnt acts on (resolving or marking a thread does not signal anything to CodeAnt), so the primary feedback mechanism is always the `@codeant-ai:` tagged reply itself, not any thread state.

## Custom Instructions

Repository-scoped review rules can be configured at `app.codeant.ai/settings/learnings` > Instructions, using glob file patterns (e.g., `**/*.tsx`) to adjust what CodeAnt flags.

---
name: review-ticket-human
description: Review a Jira ticket for readiness for human work — not agent/spec-first development. Checks that AC states outcomes (not implementation steps), description is terse with clear scope/out-of-scope, and the ticket is actionable without over-prescribing. Use this when the user asks to review a ticket for humans, review ticket quality, check if a ticket is ready for work by a person, or says "review OP-XXXX for human work".
---

# Review Jira Ticket (Human Work)

Review a Jira ticket to check it's ready for a human to pick up and work on. The goal is a ticket that communicates the desired outcome clearly without prescribing how to get there or drowning in implementation details.

This is NOT about agent-readiness or spec-first development. It's about whether a person reading this ticket knows what "done" looks like.

## Fetch the ticket

- Ticket ID: $ARGUMENTS
- cloudId: `fff788d2-8a2a-4c36-a884-dde2bb4a2b49`

Fetch in parallel:
1. `getJiraIssue` for summary, description, status, type
2. `jira issue view <KEY> --raw | jq '.fields.customfield_10216'` for AC (custom field, not returned by MCP)

## What to check

### Description
- **Has intent**: Why does this work matter? One sentence is fine.
- **Has scope**: What's included. Terse — a list or a sentence, not paragraphs.
- **Has out-of-scope** (when needed): Prevents scope creep. Especially important when adjacent work exists that someone might assume is included.
- **No redundancy**: Don't repeat what's already in AC or out-of-scope. Each piece of info lives in exactly one place.
- **Uses human names**: Team names ("Peng"), not technical identifiers ("bp_pe"). Product names, not internal codes.
- **No implementation details**: No file paths, no "update X then Y" sequences. That's planning, not the ticket.

### Acceptance Criteria
- **States outcomes, not steps**: "Atlantis works with GitHub-only config" not "remove GitLab config block from values.override.yaml in gitops and sandbox-gitops"
- **Each item is verifiable**: Someone can look at it and say pass or fail
- **One outcome per item**: Don't cram "X and Y and Z" into a single checkbox. Split them.
- **Grouped under bold headers** when there are 4+ items across distinct categories
- **No file paths or tool names**: AC says what's true when the work is done, not which files to touch
- **Correct intent over consistent phrasing**: If the action is "move" not "delete", say "move". Getting the actual outcome right matters more than matching a template.

### Slop Check

Flag any of these — they're signs the ticket was padded rather than written:

**AI-generated filler** — words that sound professional but carry zero information:
- "ensure robust/comprehensive/seamless", "leverage existing", "streamline the process"
- "facilitate", "utilize" (instead of "use"), "implement a solution for" (instead of just saying what)
- "This will enable..." preambles that delay the actual point
- Any sentence you could delete without losing information — delete it

**Redundancy:**
- Title restated in the description ("Summary: Update cross-repo references. Description: This ticket is about updating cross-repository references...")
- Same information in both description and AC
- AC items that restate each other with slightly different wording
- "As described above" or "per the requirements" — just say the thing

**Vague hedging:**
- "if applicable", "as needed", "where appropriate" — either it's in scope or it isn't
- "various", "multiple", "several" without saying which ones
- "etc.", "and so on" — list the actual items or don't mention them

**Over-qualification:**
- Explaining why obvious things are important ("security is critical because...")
- Caveats on every statement ("it should be noted that", "it is worth mentioning")
- Meta-commentary about the ticket itself ("this ticket covers", "the goal of this task is")

When flagging slop, quote the offending text and suggest a terse replacement (or deletion).

### Structure & Sizing
- **Is it one piece of work?** If the ticket has unrelated AC categories that could be done independently by different people, it might need splitting.
- **Are there hidden blockers?** Dependencies that aren't called out (e.g., AC assumes another ticket is done first).
- **Is it too vague to estimate?** A human should be able to roughly gauge effort from the AC.

## What NOT to flag

- Missing "behavior scenarios" or "edge cases" — that's agent-spec thinking. Humans figure out edge cases.
- Missing test plans — unless the ticket is about testing.
- Implementation approach — humans choose their own approach.
- Lack of specific technical constraints — unless the ticket genuinely needs them (e.g., "must not break X").

## Output format

```
## Review: {ticket_id} — {title}

**Verdict**: [READY / NEEDS WORK / BLOCKED]

### What's good
- [Strengths worth keeping]

### Issues
- [What needs fixing, with specific suggestions]

### Suggested changes
[Concrete rewrites or additions — not just "clarify X" but "change X to Y"]
```

Keep it short. If the ticket is ready, say so and move on. Don't pad the review with filler praise.

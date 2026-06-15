---
name: monthly-rec-meeting-record
description: >
  Generates a polished, presentation-ready status report for the monthly recurring meeting
  of the Platform Engineering & IT team (peng-and-it_t2). Use this skill whenever the user
  asks to prepare or generate the monthly rec meeting record, sprint update, peng-and-it
  status report, or monthly team update. Also trigger when the user says "prepare the
  monthly meeting", "generate the rec meeting report", "what happened this month in
  peng-and-it", or anything implying they want a summary of recent epic progress for the
  monthly recurring team meeting.
---

# Monthly Rec Meeting Record

Generates a presentation-ready HTML status report for the monthly Platform Engineering & IT
recurring meeting. It queries Jira for epics labeled `peng-and-it_t2` in the OP project,
filters to what's active or recently shipped, collects comments and completed sub-tickets,
and renders a polished widget.

## Step 1 — Compute the date window

Today's date is provided in your context. The look-back window is the **last 30 days**
(i.e., today minus 30 days). Use this as the cutoff for all "within last month" filters.

## Step 2 — Get the Jira cloud ID

Call `getAccessibleAtlassianResources`. The cloud ID for `aignx.atlassian.net` is
`fff788d2-8a2a-4c36-a884-dde2bb4a2b49` — use it directly unless that call fails.

## Step 3 — Fetch all epics with label `peng-and-it_t2`

Use `searchJiraIssuesUsingJql` with:
- `jql`: `project = OP AND issuetype = Epic AND labels = "peng-and-it_t2"`
- `fields`: `["summary", "status", "assignee", "comment", "description"]`
- `maxResults`: 50
- `responseContentFormat`: `markdown`

**Important — large responses**: The result will almost certainly exceed the inline token
limit and be saved to a file. When that happens, parse it with Python:

```bash
cat <path-to-file> | python3 -c "
import json, sys
data = json.load(sys.stdin)
issues = data['issues']['nodes']
# process as needed
"
```

## Step 4 — Filter to relevant epics

From the full list, keep only epics that meet **at least one** of these criteria:

1. **Status is `In Progress`**
2. **Status is `Done` AND the epic was moved to Done within the last 30 days**

For criterion 2: check whether any comment on the epic was created within the last 30 days
and references completion (a proxy for recently-shipped). If the epic is `Done` and has
no comments at all, it was likely shipped earlier — exclude it.

The result is a shortlist of 6–10 epics to focus on.

## Step 5 — Extract comments from the last 30 days

For each shortlisted epic, extract comments whose `created` timestamp is >= the cutoff date.

ADF (Atlassian Document Format) comment bodies are JSON trees. Extract plain text with:

```python
def extract_text(node):
    if isinstance(node, str): return node
    if isinstance(node, dict):
        if node.get('type') == 'text': return node.get('text', '')
        return ''.join(extract_text(c) for c in node.get('content', []))
    return ''
```

Keep at most ~400 characters per comment body to stay concise.

## Step 6 — Fetch child tickets moved to Done in the last 30 days

Run a second `searchJiraIssuesUsingJql` query:

```
project = OP
AND "Epic Link" in (<comma-separated epic keys from shortlist>)
AND status changed to Done after "<cutoff-date-YYYY-MM-DD>"
ORDER BY "Epic Link" ASC
```

Fields: `["summary", "status", "assignee", "customfield_10014", "description"]`

`customfield_10014` holds the parent epic key. Parse the result the same way as Step 3.

Group the resulting tickets by epic key.

Extract a short description (first 200 characters) from each ticket's description field,
applying `extract_text` if the body is ADF.

## Step 7 — Compute summary metrics

- Epics shipped (Done): count of recently-Done epics in the shortlist
- Epics in progress: count of In Progress epics in the shortlist
- Tickets completed: total child tickets found in Step 6
- Contributors: count of unique assignees across all child tickets + epic owners

## Step 8 — Render the HTML widget

Call `mcp__visualize__show_widget` with `title` = `peng_it_monthly_update_<YYYY_MM>` and
`loading_messages` appropriate to the context.

The widget must follow the design system (CSS variables, no hardcoded colors, dark-mode
safe). Use the exact structure below as a template — do not shrink or omit sections.

### Widget structure

```
Header
  h1: "Platform Engineering & IT — Monthly Update"
  subtitle: "<Month Year> · Epics labeled peng-and-it_t2"

Metrics row (4 cards, grid)
  Epics shipped | Epics in progress | Tickets completed | Contributors

Section label: "Shipped this month"
  One epic-card per Done epic (green left border)

Section label: "In progress"
  One epic-card per In Progress epic (blue left border)
```

### Epic card anatomy

Each card contains:
- Epic key (small muted text, e.g. "OP-2946")
- Epic title (15px, weight 500)
- Status pill ("Done" = green pill, "In Progress" = blue pill)
- Owner row: initials avatar + display name
- Progress bullets: 2–4 key points distilled from the recent comments
  (if no recent comments, write "No status updates this month.")
- Tickets block (only when child tickets exist):
  Label "N tickets completed" + pill list of ticket keys + short summaries

### Colors

Use these exact hex values (they are safe in both light and dark mode via CSS vars):

| Purpose | Hex |
|---------|-----|
| Shipped left border | `#3B6D11` |
| In Progress left border | `#185FA5` |
| Done pill bg | `#EAF3DE` |
| Done pill text | `#3B6D11` |
| In Progress pill bg | `#E6F1FB` |
| In Progress pill text | `#185FA5` |
| Avatar bg | `var(--color-background-info)` |
| Avatar text | `var(--color-text-info)` |

### Progress bullets

Synthesize the recent comments into **2–4 concise bullets** per epic. Do not copy-paste
full comment text — distil the key facts:
- What was completed or decided
- What the current blocker or risk is (if any)
- What the next concrete step is

If the epic has no recent comments but has completed sub-tickets, infer progress from those
ticket summaries instead.

## Output

The widget renders inline. After it appears, add a one-sentence note telling the user they
can screenshot it or print-to-PDF from the browser for the presentation.

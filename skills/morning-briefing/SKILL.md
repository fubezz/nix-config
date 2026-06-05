---
name: morning-briefing
description: >
  Prepare a morning briefing by collecting unread Slack messages (DMs and mentions),
  unread Gmail inbox threads, and recently shared/modified Google Docs from the last 24 hours.
  Synthesizes everything into a prioritized overview highlighting urgent items.
  Trigger phrases: "morning briefing", "daily briefing", "morning standup prep",
  "what did I miss", "catch me up", "/morning-briefing".
---

# Morning Briefing

Consolidates personal Slack activity, unread email, and recent Google Docs into a single
prioritized briefing. Run each morning to start the day informed.

---

## Configuration

Edit these values to customize the briefing:

```
VIP_SENDERS: []          # Email addresses/names that always get high priority
                         # e.g. ["cto@aignostics.com", "alice@aignostics.com"]
TIME_WINDOW_HOURS: 24    # How far back to look (use 48 on Mondays)
```

---

## Step 1 — Determine the time window

Compute the cutoff timestamp: current time minus `TIME_WINDOW_HOURS` hours.

- For Slack searches: format as `YYYY-MM-DD` (date-based filters)
- For Drive queries: format as RFC 3339, e.g. `2026-04-21T08:00:00Z`
- Note today's date and day of week. If it's Monday, consider using 48h window.

---

## Step 2 — Slack: Personal Messages

**Goal**: find DMs and channel mentions directed at the user in the last 24h.

### 2a — Resolve Slack identity

Call `slack_search_users` with:
```
query: "fabian@aignostics.com"
limit: 1
```
Extract the user's Slack `user_id` (format: `U` followed by alphanumerics, e.g. `U0123ABC`).

### 2b — Fetch direct mentions

Call `slack_search_public_and_private` with:
```
query: "<@USER_ID>"
after: <cutoff-date YYYY-MM-DD>
limit: 20
```

### 2c — Fetch DMs

Call `slack_search_public_and_private` with:
```
query: "to:<@USER_ID>"
after: <cutoff-date YYYY-MM-DD>
limit: 20
```

### 2d — Deduplicate and score

Merge both result sets. Drop duplicates by message `ts`. For each message, assign a priority score:

| Signal | Points |
|--------|--------|
| Direct mention (`@fabian`) or DM | +1 |
| Keyword: `urgent`, `asap`, `p0`, `p1`, `incident`, `alert`, `critical`, `deadline`, `broken`, `down`, `failed`, `help` | +1 |
| Sender is in `VIP_SENDERS` | +1 |

Score 2–3 → 🔴 High Priority | Score 1 → 🟡 Notable | Score 0 → omit

---

## Step 3 — Gmail: Unread Inbox

Call `search_threads` with:
```
query: "is:unread in:inbox"
pageSize: 50
```

For the **top 15** thread IDs by recency, call `get_thread` with `messageFormat: FULL_CONTENT`.
For remaining threads, note subject + sender only (no full fetch).

### Priority scoring for email

| Signal | Points |
|--------|--------|
| Email sent directly TO user (not CC/BCC) | +1 |
| Subject contains: `urgent`, `action required`, `critical`, `deadline`, `incident`, `alert`, `p0`, `p1`, `please review`, `approval needed` | +1 |
| Sender address/name is in `VIP_SENDERS` | +1 |
| Sent outside business hours (before 8am or after 7pm) | +1 |

Score 2–3 → 🔴 High Priority | Score 1 → 🟡 Notable | Score 0 → brief count only

---

## Step 4 — Google Drive: Recent Documents

### 4a — Recently shared with me

Call `search_files` with:
```
query: "sharedWithMe and modifiedTime > '<RFC3339-cutoff>'"
pageSize: 20
```

### 4b — Recently modified (owned or collaborated)

Call `search_files` with:
```
query: "modifiedTime > '<RFC3339-cutoff>'"
pageSize: 20
```

### 4c — Score and filter

Deduplicate by file ID. Score each file:

| Signal | Points |
|--------|--------|
| Title contains: `review`, `please review`, `action`, `approve`, `feedback`, `urgent`, `decision` | +1 |
| File was newly shared with me (not just modified) | +1 |
| File is a Doc or Slide (not just a Sheet or folder) | +1 (slight weight) |

Score 2–3 → 🔴 High Priority | Score 1 → 🟡 Notable

For the top 3 highest-priority docs, call `read_file_content` to fetch a brief snippet
(first 200 words) for context.

---

## Step 5 — Synthesize and Output

Produce the briefing in this format:

```markdown
# Morning Briefing — <Day, Month DD YYYY>

## 🔴 High Priority (Action Required)
- **[Slack/Email/Doc]** <sender/channel> — <one-line summary> [link if available]
- ...

## 🟡 Notable
- **[Slack]** <channel> — <summary>
- **[Email]** <from> — <subject>
- ...

---

## Slack
**<N> messages** (mentions + DMs in the last 24h)
<brief grouped summary by sender or thread>

## Email
**<N> unread** threads in inbox
<list: sender — subject — one-liner>

## Google Docs
**<N> recently active** documents
<list: title (link) — who shared / last modified>

---

## Action Items
- [ ] <concrete action 1>
- [ ] <concrete action 2>
```

### Writing the action items

Extract concrete next steps from high-priority items only. Each action item should be:
- Specific and actionable ("Reply to Alice about the Q2 budget approval")
- Not vague ("Check email")
- Tied to a specific item from the briefing

If there are no high-priority items, write: _"Nothing urgent — good morning! ☀️"_

---

## Tips

- If Slack user lookup fails, skip Step 2 and note it in the briefing header.
- If Drive search returns no results, it may mean the date filter is too strict — note it and move on.
- Keep the briefing scannable: bullet points over paragraphs, names over pronouns.
- For long email threads, summarize the latest message in the thread, not the entire history.
- Omit score-0 items entirely to keep the briefing focused.

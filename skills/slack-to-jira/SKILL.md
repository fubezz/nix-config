---
name: slack-to-jira
description: >
  Converts a Slack conversation into a Jira task in the OP board's Ninja epic (OP-1866),
  creates a feature branch in a given GitHub repository, and replies to the Slack thread
  with the new ticket link. Use when the user wants to turn a Slack request or discussion
  into a tracked Jira task with a corresponding branch.
  Trigger phrases: "create ticket from slack", "make a jira from this slack", "slack to jira",
  "turn this slack into a ticket", "/slack-to-jira".
---

# Slack → Jira Skill

Turns a Slack conversation into a tracked Jira task and a ready-to-use feature branch.

## Required inputs

The user must supply:
1. **Slack link** – e.g. `https://aignostics.slack.com/archives/C06D26P439V/p1775549386161419`
2. **GitHub repository** – in `owner/repo` format, e.g. `aignostics/infrastructure`

If either is missing, ask before proceeding:
> "Please provide the Slack link and the GitHub repository (owner/repo) you'd like to branch in."

---

## Step 1 — Parse the Slack URL

Extract `channel_id` and `message_ts` from the URL:
- URL format: `.../archives/<CHANNEL_ID>/p<TS_NO_DOT>`
- Convert the timestamp: insert a `.` after the 10th digit of the numeric part
  - e.g. `p1775549386161419` → `1775549386.161419`

---

## Step 2 — Read the Slack thread

Call `slack_read_thread` with the extracted `channel_id` and `message_ts`.

Summarise the thread into:
- **Title** – one concise sentence (≤80 chars) describing the request/task
- **Description** – a short paragraph or bullet list covering:
  - What is being requested
  - Context / background from the thread
  - Who requested it (Slack display name)
  - Any decisions or agreements already made in the thread

---

## Step 3 — Create the Jira ticket

Use `createJiraIssue` with:
- **cloudId**: `aignx.atlassian.net`
- **project**: `OP`
- **issuetype**: `Task`
- **summary**: the title from Step 2
- **description**: the description from Step 2 — **always use ADF format** (never pass as a markdown string, as `\n` escape sequences do not render). Structure as a `doc` with `paragraph`, `bulletList`, and `listItem` nodes. Use `"marks": [{"type": "strong"}]` for bold text. Do NOT use `contentFormat: markdown` — pass raw ADF JSON in the `fields` object.
- **parent** (epic link): `OP-1866`  ← the Ninja epic "Platform Engineering Support Operations (Ninja)"
- **additional_fields**: The OP project requires `customfield_10216` (Acceptance Criteria) in ADF format. Derive 2–3 acceptance criteria from the thread and pass them as:
  ```json
  {
    "customfield_10216": {
      "version": 1, "type": "doc",
      "content": [{"type": "bulletList", "content": [
        {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "<criterion 1>"}]}]},
        {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "<criterion 2>"}]}]}
      ]}]
    }
  }
  ```

Capture the new issue key (e.g. `OP-2567`) and its web URL from the response.

---

## Step 4 — Create the feature branch

Derive a branch name from the issue key and title:
- Format: `feat/<ISSUE-KEY>-<slugified-title>`
- Slugify: lowercase, replace spaces/special chars with `-`, max 50 chars total after the prefix
- Example: `feat/OP-2567-add-npm-artifact-registry`

Create the branch via the GitHub CLI against the default branch of the target repo:

```bash
gh api repos/<OWNER>/<REPO>/git/refs \
  --method POST \
  --field ref="refs/heads/<BRANCH_NAME>" \
  --field sha="$(gh api repos/<OWNER>/<REPO>/git/refs/heads/main --jq '.object.sha')"
```

If `main` doesn't exist, try `master`. If the branch already exists, append the issue key suffix and retry once.

---

## Step 5 — Reply in Slack

Use `slack_send_message` to post a reply **in the thread** (set `thread_ts` to the parent message timestamp):

```
Jira ticket created: <ISSUE-URL> (<ISSUE-KEY>)
Branch `<BRANCH_NAME>` created in <OWNER>/<REPO>.
```

Use the channel_id from Step 1 and the original message_ts as `thread_ts`.

---

## Error handling

- If the Slack thread is empty or unreadable → tell the user and stop.
- If Jira ticket creation fails → report the error; do not create the branch or reply.
- If branch creation fails (e.g. repo not found, no permission) → report the error; still post the Jira link to Slack without the branch line.
- If the Slack reply fails → report it to the user but don't undo the ticket or branch.

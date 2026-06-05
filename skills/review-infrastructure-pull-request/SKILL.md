---
name: review-infra-pr
skill_dir: /Users/fabian/.claude/skills/review-infra-pr
description: >
  Reviews infrastructure pull requests by inspecting changed IaC files and parsing Atlantis
  bot comments (plan output and policy checks). Alerts on resource replacements, destructions,
  and policy violations (WARN/ERROR). Use when the user says "review infra PR", "check PR",
  "review infrastructure PR", "/review-infra-pr", or provides a GitHub PR URL or number for
  an infrastructure repository.
  Trigger phrases: "review infra PR", "check infrastructure PR", "review PR", "/review-infra-pr".
---

# Infrastructure PR Review

Reviews infrastructure PRs end-to-end: file-level code suggestions, Atlantis plan analysis,
and policy violation summary.

## Required inputs

The user must supply a **PR URL or number** and optionally a **repo** (`owner/repo`).

If both are missing, ask:
> "Please provide the GitHub PR URL or number (and the repo as owner/repo if not a URL)."

---

## Step 1 — Resolve PR coordinates

If the user provided a full GitHub URL (e.g. `https://github.com/org/repo/pull/123`), extract
`owner/repo` and the PR number from it.

If only a number was given without a repo context, check if there is a current working directory
with a git remote — run:

```bash
git remote get-url origin 2>/dev/null
```

and parse the owner/repo from the remote URL. If that also fails, ask the user for the repo.

---

## Step 2 — Fetch all PR data in one shot

Run this **single command** (one approval instead of many):

```bash
SKILL_DIR=/Users/fabian/.claude/skills/review-infra-pr
"$SKILL_DIR/scripts/fetch_and_analyze.sh" <OWNER> <REPO> <NUMBER> "$SKILL_DIR" > /tmp/pr_data.json
```

This fetches PR metadata, changed files, the full diff, and all Atlantis plan/policy data in
parallel and writes a single JSON object to `/tmp/pr_data.json` with keys: `meta`, `files`,
`diff`, `atlantis`.

**Important:** always write to a file — do NOT use `PR_DATA=$(...)` variable capture, as control
characters in the PR body or diff will corrupt the JSON when passed through a shell variable.

Extract what you need with inline python3 reading from the file:

```bash
# PR header fields
python3 -c "import json; d=json.load(open('/tmp/pr_data.json'))['meta']; print(d['title'], d['url'])"

# Diff
python3 -c "import json; print(json.load(open('/tmp/pr_data.json'))['diff'])"

# Atlantis summary
python3 -c "import json; print(json.dumps(json.load(open('/tmp/pr_data.json'))['atlantis'], indent=2))"

# All at once
python3 -c "
import json
d = json.load(open('/tmp/pr_data.json'))
m = d['meta']; a = d['atlantis']
print('title:', m['title'])
print('author:', m['author']['login'])
print('files:', d['files'])
print('atlantis:', json.dumps(a, indent=2))
print('diff:')
print(d['diff'])
"
```

Print a brief header:

```
## PR: <title>
**Author:** <author>  **Branch:** <head> → <base>  **State:** <state>
**URL:** <url>
```

---

## Step 3 — Review changed IaC files

Scan the diff for the following file types: `*.tf`, `*.tfvars`, `*.hcl`, `*.yaml`, `*.yml`,
`*.json`, `Dockerfile`, `*.sh`, `*.py` (any infrastructure-as-code or config file).

For each changed file, analyse the diff and flag:

### Things to look for in Terraform / HCL
- **Hardcoded secrets or credentials** — API keys, passwords, tokens in plain text
- **Missing `lifecycle` blocks** — resources that are stateful (databases, storage buckets, IAM
  bindings) and lack `prevent_destroy = true`
- **Overly permissive IAM** — wildcards in roles or principals (e.g. `roles/*`, `allUsers`)
- **Missing tags/labels** — resources without mandatory cost-attribution or environment labels
- **Deprecated resource types** — e.g. `google_container_cluster` arguments that are deprecated
- **Undeclared variables** — references to `var.X` that are not defined in variables files
- **Version pinning** — provider or module versions that use `~>` ranges or are unpinned
- **Backend config changes** — changes to `backend {}` blocks that could affect state storage

### Things to look for in YAML / Helm / Kubernetes
- **Missing resource limits/requests** — containers without CPU/memory limits
- **`latest` image tags** — non-deterministic image references
- **Privileged containers** — `securityContext.privileged: true`
- **Host namespace sharing** — `hostPID`, `hostNetwork`, `hostIPC` set to true

### Output format for code suggestions

Group by file. For each suggestion:

```
### `path/to/file.tf`
- **[SEVERITY]** Line ~N: <short description>
  ```hcl
  # suggested change (if applicable)
  ```
```

Severity levels: `ERROR` (security/correctness), `WARN` (best practice), `INFO` (optional improvement).

If a file has no issues, do not list it — only report files with findings.

If there are no findings at all, say: "No code issues found in the changed files."

---

## Step 4 — Extract Atlantis results from PR_DATA

The `$PR_DATA["atlantis"]` field already contains the fully parsed Atlantis output from Step 2.
No additional fetch is needed. The parsed fields are:

- `plan_summaries` — per-dir `{dir, summary, adds, changes, destroys}`
- `destructions` — `{dir, resource}` for destroyed resources
- `replacements` — `{dir, resource, reason}` for -/+ replacements
- `locked_dirs`, `output_only_dirs`, `no_changes_dirs`
- `policy_warns` — deduplicated `{dir, file, rule, message}` WARN violations
- `policy_denies` — deduplicated DENY/FAIL/ERROR violations
- `warn_count` / `deny_count`

Extract with:

```bash
python3 -c "
import json
a = json.load(open('/tmp/pr_data.json'))['atlantis']
print('replacements:', json.dumps(a['replacements'], indent=2))
print('destructions:', json.dumps(a['destructions'], indent=2))
print('policy_warns:', json.dumps(a['policy_warns'], indent=2))
print('policy_denies:', json.dumps(a['policy_denies'], indent=2))
print('plan_summaries:', json.dumps(a['plan_summaries'], indent=2))
print('locked_dirs:', json.dumps(a['locked_dirs'], indent=2))
"
```

---

## Step 5 — Produce the review summary

Output the final report in this order:

---

```
# Infrastructure PR Review

## PR: <title>
<url>

---

## 🔴 Destructions & Replacements
```

If any resources are being destroyed or replaced, list them as a table:

| Resource | Change Type | Reason |
|----------|-------------|--------|
| `module.x.resource_type.name` | REPLACE | `attribute X forces replacement` |
| `module.y.resource_type.name` | DESTROY | — |

**If this section is empty**, print:
> ✅ No destructions or replacements detected.

---

```
## 🟠 Policy Violations
```

### Errors / DENY
List each as:
- `DENY` **rule-name** (`file`): message

### Warnings / WARN
List each as:
- `WARN` **rule-name** (`file`): message

**If no violations**, print:
> ✅ All policy checks passed.

---

```
## 🔵 Plan Summary
```

For each workspace/directory, print the summary line:
> `<dir>`: Plan: X to add, Y to change, Z to destroy.

---

```
## 🟡 Code Review Suggestions
```

Paste the per-file suggestions from Step 3 here.

---

```
## ✅ Next Steps
```

Bullet list of recommended actions:
- If destructions/replacements: "Review the replacement plan for `<resource>` — confirm intentional before approving."
- If DENY policies: "Policy check is blocking apply — resolve DENY violations before merging."
- If WARN policies: "Address WARN violations or document exceptions in the PR description."
- If code issues with severity ERROR: "Fix ERROR-level code issues before merging."
- If nothing critical: "Looks good — no blockers found."

---

## Scripts and dependencies

This skill ships helper scripts in `scripts/`. No pip packages required — stdlib only.

### scripts/fetch_and_analyze.sh  ← PRIMARY ENTRY POINT

Fetches PR metadata, diff, files, and Atlantis plan/policy data **in parallel** and returns a
single JSON object. Requires: `gh` (authenticated), `python3` (stdlib).

```bash
SKILL_DIR=/Users/fabian/.claude/skills/review-infra-pr
PR_DATA=$("$SKILL_DIR/scripts/fetch_and_analyze.sh" <OWNER> <REPO> <PR_NUMBER> "$SKILL_DIR")
```

Output keys: `meta`, `files`, `diff`, `atlantis` (see Step 2/4 above for field details).

### scripts/parse_atlantis.py  ← used internally by fetch_and_analyze.sh

Can also be invoked standalone for debugging:

```bash
gh api repos/<OWNER>/<REPO>/issues/<NUMBER>/comments --paginate \
  --jq '.[] | select(.user.login | test("atlantis|github-actions"; "i")) | {id:.id,body:.body,created_at:.created_at}' \
  | python3 /Users/fabian/.claude/skills/review-infra-pr/scripts/parse_atlantis.py --mode all
```

## Error handling

- If `gh` is not authenticated → tell the user to run `gh auth login` and stop.
- If no Atlantis comments are found → note "No Atlantis comments found yet — the plan may not have run. Trigger it with `atlantis plan` as a PR comment." Still proceed with the code review.
- If the PR diff is too large to analyse fully → note which files were skipped and why.
- If the repo cannot be determined → ask the user before proceeding.

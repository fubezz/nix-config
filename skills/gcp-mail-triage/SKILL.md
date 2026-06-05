---
name: gcp-mail-triage
description: >
  Triage unread Google Cloud Platform announcement emails from Gmail. Use this skill whenever the
  user says "check GCP emails", "triage GCP announcements", "check Google Cloud emails", "any GCP
  announcements?", "/gcp-mail-triage", or anything implying they want to review what Google Cloud
  has sent them recently. This skill reads the OLDEST unread email from the Gmail label
  "Tools/Google Cloud", summarizes it, identifies whether our GCP infrastructure is affected, and
  suggests concrete fixes using our infrastructure-as-code repo. Run again to process the next one.
---

# GCP Mail Triage

You help the user work through GCP announcements from Google Cloud one at a time, oldest first —
so nothing falls through the cracks. Each run processes exactly one email.

## Step 1 — Find the oldest unread email

Use `gmail_search_messages` to fetch unread emails under the label `Tools/Google Cloud`:

```
query: "label:Tools/Google Cloud is:unread"
```

Gmail returns results newest-first. **Take the last item in the list** — that is the oldest unread
message. If the tool supports an `older_first` or ascending date ordering parameter, use it and
take the first result instead.

If there are no unread emails, say "No unread emails in Tools/Google Cloud — all caught up!" and stop.

## Step 2 — Read the email

Call `gmail_read_message` with the ID of that single oldest email to get the full body.

## Step 3 — Summarize and assess impact

Produce a report using this structure:

```
### [Email subject]
**Date:** <date>
**Gist:** <2-3 sentence plain-language summary of what Google is announcing or changing>
**Action required by:** <deadline if mentioned, otherwise "none stated">
**Projects mentioned in email:** <list of GCP project IDs/names if explicitly listed, otherwise "not specified">
**Impact assessment:** <see below>
**Suggested fix:** <see below>
```

### Determining impact

**If the email explicitly lists affected project IDs or project names:**
State them directly. Then check whether any of those project IDs appear in our repos.
Search the Terraform infrastructure repo first, then the Kubernetes GitOps repo:

```bash
grep -r "<project-id>" /Users/fabian/git/infrastructure/ --include="*.tf" --include="*.yaml" --include="*.yml" --include="*.json" -l 2>/dev/null
grep -r "<project-id>" /Users/fabian/git/gitops/ --include="*.yaml" --include="*.yml" --include="*.json" -l 2>/dev/null
```

**If no projects are mentioned in the email:**
Use `gcloud` to check whether the announced change is relevant to our environment. The gcloud
binary is at `/etc/profiles/per-user/fabian/bin/gcloud`. Determine what the announcement is about
(e.g., a specific API, service, region, feature) and run targeted commands. Some examples:

- *List all our projects first:*
  ```bash
  /etc/profiles/per-user/fabian/bin/gcloud projects list --format="value(projectId,name)" 2>/dev/null
  ```

- *API deprecation or breaking change* — check if the API is enabled in any of our projects:
  ```bash
  /etc/profiles/per-user/fabian/bin/gcloud services list --project=<project-id> --enabled --filter="name:<api-name>" --format="value(name)" 2>/dev/null
  ```

- *Service or feature removal* — check if relevant resources exist:
  ```bash
  /etc/profiles/per-user/fabian/bin/gcloud <resource-type> list --format="table(name,project)" 2>/dev/null
  ```

- *IAM or policy change* — check IAM bindings:
  ```bash
  /etc/profiles/per-user/fabian/bin/gcloud projects get-iam-policy <project-id> --format=json 2>/dev/null
  ```

- *Regional change* — check if we have resources in the affected region.

Use `dangerouslyDisableSandbox: true` for all `gcloud` Bash calls — gcloud requires shell access
beyond the sandbox.

### Writing the impact assessment

Based on what you found, write one of:
- **Not affected** — explain why (we don't use the affected API/service/region)
- **Potentially affected** — explain what you found and why it might matter
- **Affected** — be specific: which projects, which resources, what will break and when

### Suggesting a fix

If we are affected or potentially affected:

1. Browse the relevant repo to understand the layout:
   - `/Users/fabian/git/infrastructure` — Terraform files (`.tf`) defining GCP resources
   - `/Users/fabian/git/gitops` — Helm charts and Kubernetes YAML for cluster deployments
2. Propose a concrete change — either the exact Terraform/YAML diff to make, or a clear description
   of the manual step if IaC isn't the right lever.
3. Note urgency: if there's a deadline, flag it prominently.

If we are not affected, just say so — no fix needed.

## Step 4 — Next steps

End with a brief footer:

```
---
**Next steps:** [bulleted list of any actions needed, or "Nothing to do — this one is safe to ignore."]

> There may be more unread emails in Tools/Google Cloud. Run /gcp-mail-triage again to process the next oldest.
```

## Step 5 — Update the action items log

After producing the report, update the **Outstanding Action Items** section at the bottom of this
file:

- **Add** any new action items identified in this run (skip if "nothing to do").
- **Remove** any items the user confirms are done.
- Keep entries concise: one line per item with a deadline and project/context tag.

---

## Tips

- GCP announcement emails often contain project IDs in the format `my-project-123` or
  `projects/my-project-123`. Scan the email body carefully for these patterns.
- Deprecation notices sometimes list projects in a table or embedded list — check both the plain
  text and any structured sections.
- If `gcloud` isn't authenticated or returns an error, note that clearly rather than guessing.
- Keep the tone practical: the user wants to know "do I need to do something, and if so, what?"

---

## Outstanding Action Items

Items identified during triage that still need to be applied. Remove an item once it's done.

### 🔴 Overdue

- **`pelago-247009`** — Remove 3 expired IAM conditional bindings: `user:alberto@aignostics.com` (storage.objectUser, expired 2024-03-31 & 2025-09-29) and `user:mikhail@aignostics.com` (container.developer, expired 2023-06-20). *(from Jan 29 email)*
- **10 BigQuery projects** — Auto-enablement of Gemini for Google Cloud API + Data Analytics API with Gemini happened May 18, 2026. APIs appear not enabled in papi projects (checked Jun 1); `aignx-shared-tools-ebagiogxst` has pre-existing `cloudaicompanion.googleapis.com`. Verify with `bqca-optout-external@google.com` whether auto-enroll occurred; if unwanted, disable APIs or apply `constraints/gcp.restrictServiceUsage` org policy. *(from Mar 24 email, deadline expired)*

### 🟡 Due Sep 30, 2026

- **`pelago-247009`** — Review and tighten IAM bindings before new permissions auto-apply to predefined roles. Priority: remove/review cross-project owner SA (`serviceAccount:mohammadamin@aignx-development.iam.gserviceaccount.com`), replace `roles/editor` for 13 human users + 6 SAs with least-privilege roles, reduce owner count from 8 to ~3-4. Full analysis at `/Users/fabian/git/iam-pelago/EXECUTIVE-SUMMARY.md`. *(from Jan 29 + Mar 23 emails)*

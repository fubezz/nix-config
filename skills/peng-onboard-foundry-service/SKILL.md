---
name: peng-onboard-foundry-service
description: >
  Onboard a new Foundry Python service to Aignostics GCP infrastructure. Use this skill
  whenever someone asks to onboard, register, or set up a new Foundry service, add a new
  service to the infrastructure, or when a Jira ticket mentions onboarding a new Foundry
  Python service. Also trigger for phrases like "add SERVICE to infra", "create infra for
  SERVICE", "set up GCP for SERVICE".

  This skill covers the full onboarding workflow:
  1. Create a Jira ticket in the OP board (Ninja epic)
  2. Infrastructure repo: add shared-VPC subnets + 4 service-project dirs (dev/test/stage/prod)
     with chained PRs
  3. Gitops repo: add the service's GitHub repo to the Atlantis allowlist
  4. Post a Shared VPC / infra summary comment to the Jira ticket
---

# Foundry Service Onboarding

## Step 0 — Collect inputs

Ask the user for (if not already provided):

| Input | Example | Notes |
|-------|---------|-------|
| `service_name` | `foundry-example-service` | Full service name, used in GCP folder + subnet names |
| `abbreviation` | `fes` | Short alias for GCP project name (`aignx-<abbr>-dev-XXXX`). Keep ≤5 chars so total GCP project name stays ≤30 chars |
| `github_repo` | `foundry-example-service` | GitHub repo under `aignostics/` org |
| `jira_ticket` | `OP-2813` | If already exists — otherwise create one (see Step 1) |

Also confirm the **next available IP range** (see Step 2 before writing any files).

---

## Step 1 — Create Jira ticket

Create a ticket in the **OP board**, **Ninja epic (OP-1866)**, current active sprint.

Use the `createJiraIssue` MCP tool. Required fields:

```json
{
  "project": "OP",
  "issuetype": "Task",
  "summary": "task(OP-XXXX): onboard <service_name> to Aignostics infrastructure",
  "description": <ADF>,
  "customfield_10216": <ADF>,   // Acceptance Criteria — required, must be ADF
  "customfield_10014": "OP-1866", // Epic link
  "customfield_10020": <sprint_id_integer>
}
```

Get the current sprint ID by calling `searchJiraIssuesUsingJql` with:
```
project = OP AND sprint in openSprints() AND sprint not in closedSprints()
```
Extract the `customfield_10020[0].id` integer value from any result.

**Description ADF** (paragraph format):
```json
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "paragraph",
    "content": [{"type": "text", "text": "Onboard <service_name> service to the Aignostics GCP infrastructure. This includes setting up Shared VPC subnets, service projects for dev/test/stage/prod environments, Terraform state buckets, and registering the GitHub repo with Atlantis."}]
  }]
}
```

**Acceptance Criteria ADF** (bullet list):
```json
{
  "type": "doc", "version": 1,
  "content": [{
    "type": "bulletList",
    "content": [
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "Shared VPC subnets created for dev/test/stage/prod in europe-west4"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "GCP service projects aignx-<abbr>-dev/test/stage/prod created and attached to host VPC"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "Terraform state buckets created per environment"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "Atlantis allowlist updated for aignostics/<github_repo>"}]}]}
    ]
  }]
}
```

---

## Step 2 — Find next available IP range

Read `terragrunt/projects/host-project/shared-vpc/terragrunt.hcl` and find the last `subnet_ip`
block. Subnets are allocated as contiguous `/22` blocks in `10.21.x.0/22` space. Allocate the
next 4 free `/22` blocks (one per env: dev, test, stage, prod).

To verify no overlap, grep for existing `subnet_ip` values:
```bash
grep 'subnet_ip' terragrunt/projects/host-project/shared-vpc/terragrunt.hcl
```

The last known allocation was:
- `walks-into-a-bar`: `10.21.204.0/22` – `10.21.212.0/22`
- `foundry-example-service`: `10.21.216.0/22` – `10.21.228.0/22`

Subsequent services start at `10.21.232.0/22`.

---

## Step 3 — Infrastructure repo changes

### 3a. Create branch

```bash
cd /path/to/infrastructure
git checkout main && git pull
git checkout -b onboard-<service_name>
```

### 3b. Edit shared-vpc/terragrunt.hcl — COMMIT 1

Edit `terragrunt/projects/host-project/shared-vpc/terragrunt.hcl`:

**Add to `environments` list** (after the last foundry entry, with a comment):
```hcl
    "<service_name>", # <service_name>-dev, -test, -stage and -prod
```

**Add 4 subnets** (after the last existing subnet block, before any `PROXY ONLY SUBNETS` comment).
Copy the pattern exactly from an existing block (e.g. `aignx-walks-into-a-bar-prod`):

```hcl
    {
      subnet_name               = "aignx-<service_name>-dev"
      description               = "Subnet for aignx-<service_name>-dev"
      subnet_ip                 = "<dev_ip>/22"
      subnet_region             = "europe-west4"
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
      # Limit logs collection to traffic that is external to a VPC
      subnet_flow_logs_filter = "!(has(src_vpc.vpc_name) && has(dest_vpc.vpc_name))"
    },
    {
      subnet_name               = "aignx-<service_name>-test"
      ...
    },
    ...
```

**Commit — MUST include `[ignore-dependencies]`:**
```bash
git add terragrunt/projects/host-project/shared-vpc/terragrunt.hcl
git commit -m "feat(<TICKET>): [ignore-dependencies] add <service_name> subnets and environment folder"
```

> Why `[ignore-dependencies]`: The shared-vpc module has dozens of dependent service projects.
> Without this flag, Atlantis would plan all of them, causing pipeline timeouts. Only use it on
> this specific commit.

### 3c. Create the 4 project directories — COMMIT 2

Run the bundled script to generate all files from templates:

```bash
bash /Users/fabian/.claude/skills/onboard-foundry-service/scripts/create_project_dirs.sh \
  <service_name> <abbreviation> <github_repo> $(git rev-parse --show-toplevel)
```

This creates:
```
terragrunt/projects/aignx-<service_name>-{dev,test,stage,prod}/
  account.hcl
  env.hcl
  regions/region.hcl
  regions/global/service-project/terragrunt.hcl
  regions/global/cloud-storage/<github_repo>-tf-state/terragrunt.hcl
```

See `references/hcl-templates.md` for the exact file contents if you need to create or verify them manually.

**Commit:**
```bash
git add terragrunt/projects/aignx-<service_name>-*
git commit -m "feat(<TICKET>): add <service_name> service project dirs (dev/test/stage/prod)"
git push -u origin onboard-<service_name>
```

### 3d. Create chained PRs

| PR | Branch | Target | Title |
|----|--------|--------|-------|
| dev | `onboard-<service_name>` | `main` | `feat(<TICKET>): onboard <service_name> – dev` |
| test | `onboard-<service_name>-test` | `onboard-<service_name>` | `feat(<TICKET>): onboard <service_name> – test` |
| stage | `onboard-<service_name>-stage` | `onboard-<service_name>-test` | `feat(<TICKET>): onboard <service_name> – stage` |
| prod | `onboard-<service_name>-prod` | `onboard-<service_name>-stage` | `feat(<TICKET>): onboard <service_name> – prod` |

For test/stage/prod: create a new branch from the previous branch and cherry-pick (or duplicate) only the service-project + state-bucket commit — the shared-vpc commit is already in `main` by the time these are applied.

> The chained structure means each environment's PR depends on the previous one being merged.
> Atlantis will plan/apply each independently once the target branch is up-to-date.

Create PRs with `gh pr create`:
```bash
gh pr create \
  --repo aignostics/infrastructure \
  --base main \
  --head onboard-<service_name> \
  --title "feat(<TICKET>): onboard <service_name> – dev" \
  --body "Closes <TICKET>. Adds subnets + dev service project + state bucket."
```

---

## Step 4 — Gitops repo changes

```bash
cd /path/to/gitops   # aignostics/gitops repo
git checkout main && git pull
git checkout -b onboard-<service_name>
```

Edit `applications/atlantis-helm/values.override.yaml` — add the new repo to `orgAllowlist`:

```yaml
orgAllowlist: "\
  gitlab.aignostics.com/aignx/infrastructure\
  ,github.com/aignostics/infrastructure\
  ,github.com/aignostics/foundry-python-peng-walks-into-a-bar\
  ,github.com/aignostics/<github_repo>\
  "
```

```bash
git add applications/atlantis-helm/values.override.yaml
git commit -m "feat(<TICKET>): add <github_repo> to Atlantis orgAllowlist"
git push -u origin onboard-<service_name>
gh pr create \
  --repo aignostics/gitops \
  --base main \
  --head onboard-<service_name> \
  --title "feat(<TICKET>): add <github_repo> to Atlantis allowlist" \
  --body "Allows Atlantis to process webhooks from aignostics/<github_repo>."
```

---

## Step 5 — Post Jira comment after dev is applied

Once the dev environment Atlantis `apply` has completed, post a comment on the Jira ticket
with the following information. Use `addCommentToJiraIssue` with ADF body.

The comment should include these exact details:

```
🏗️ Shared VPC Infrastructure — <service_name>

GCP Folder: <service_name>
Host Project: aignx-host-project-kah
Region: europe-west4

Subnets:
  dev   → aignx-<service_name>-dev   <dev_ip>/22
  test  → aignx-<service_name>-test  <test_ip>/22
  stage → aignx-<service_name>-stage <stage_ip>/22
  prod  → aignx-<service_name>-prod  <prod_ip>/22

GCP Projects (created by Atlantis after apply):
  dev   → aignx-<abbr>-dev-<random_suffix>
  test  → aignx-<abbr>-test-<random_suffix>
  stage → aignx-<abbr>-stage-<random_suffix>
  prod  → aignx-<abbr>-prod-<random_suffix>

Terraform State Buckets:
  dev   → aignx-<github_repo>-dev-tf-state
  test  → aignx-<github_repo>-test-tf-state
  stage → aignx-<github_repo>-stage-tf-state
  prod  → aignx-<github_repo>-prod-tf-state

Atlantis Terragrunt Paths:
  terragrunt/projects/aignx-<service_name>-dev/regions/global/service-project
  terragrunt/projects/aignx-<service_name>-dev/regions/global/cloud-storage/<github_repo>-tf-state

Infrastructure PRs:
  dev:   <pr_url>
  test:  <pr_url>
  stage: <pr_url>
  prod:  <pr_url>

Gitops PR: <pr_url>
```

Use ADF `bulletList` + `paragraph` nodes. Avoid markdown — Jira renders ADF natively.

The actual GCP project IDs (random suffix) can be retrieved from the Atlantis apply output in the
PR comments, or from the GCP console after apply. Include them if known, otherwise note
"assigned after apply — check GCP console".

---

## Hardcoded values (as of 2026-04)

| Field | Value |
|-------|-------|
| billing_id | `013CD1-01023E-EB29AA` |
| org_id | `organizations/906322165281` |
| terraform-modules ref | `v1.44.0` |
| region | `europe-west4` |
| location | `eu` |
| host project | `aignx-host-project-kah` |
| iam_terraform_owners | `group:terraform@aignostics.com`, `serviceAccount:aignx-iac-global@aignx-host-project-kah.iam.gserviceaccount.com` |
| Jira epic (Ninja) | `OP-1866` |
| Jira project | `OP` |

---

## Apply order (via Atlantis)

1. **Infrastructure PR (dev branch)**: comment `atlantis plan` on the `host-project/shared-vpc` module first → review → `atlantis apply`
2. Once shared-vpc is applied: plan+apply `aignx-<service_name>-dev/regions/global/service-project`, then `cloud-storage/<github_repo>-tf-state`
3. Merge dev PR → merge test PR (rebase on main first) → stage → prod
4. Merge gitops PR last (Atlantis accepts webhooks from that point on)

---

## Verification checklist

- [ ] GCP folder `<service_name>` visible under org in Google Cloud Console
- [ ] 4 subnets visible in Shared VPC network (`aignx-host-project-kah`)
- [ ] GCP projects `aignx-<abbr>-dev/test/stage/prod-XXXX` created, attached to host VPC
- [ ] State buckets `aignx-<github_repo>-{dev,test,stage,prod}-tf-state` exist
- [ ] Atlantis accepts webhooks from `aignostics/<github_repo>` (test by opening a PR with `atlantis plan` comment)

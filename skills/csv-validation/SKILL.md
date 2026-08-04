---
name: csv-validation
description: >
  Fills out and manages Computerized System Validation (CSV) Jira tickets in the QM project
  at Aignostics, following TI-SOP-01. Use this skill whenever the user wants to:
  - Validate a new software tool (fill out a QM CSV ticket from scratch)
  - Perform a re-evaluation or periodic monitoring of an already-approved tool
  - Decommission a validated tool
  - Transition a CSV ticket through its workflow steps
  - Create follow-up tickets for unmet tool requirements
  Trigger phrases: "fill out CSV ticket", "validate [tool name]", "CSV for [tool]",
  "re-evaluate [tool]", "monitoring due for [tool]", "do the CSV process", "github CSV",
  "tool validation", "QM-XXXX monitoring", "decommission [tool]".
---

# CSV Validation Skill

This skill automates filling out Computerized System Validation (CSV) tickets in Jira (QM project)
following Aignostics' **TI-SOP-01**.

**Authoritative source** — read it whenever anything below is ambiguous; the SOP wins:
<https://aignx.atlassian.net/wiki/spaces/QMS/pages/1993441350/TI-SOP-01+Computerized+System+Validation>
(space `QMS - Public`. A stale duplicate exists in space `QMSYSTEM` — do not use it.)

Three workflows are supported:

- **Flow A – New CSV** (SOP 3.1–3.6): A fresh ticket exists (status: *New CSV* or *evaluate*) and
  needs to be fully populated through to *Ready for approval*.
- **Flow B – Re-evaluation / Monitoring** (SOP 3.7): An existing *Tool approved* or *Monitoring*
  ticket is due for its periodic check, or a change event has triggered re-evaluation.
- **Flow C – Decommissioning** (SOP 3.8): The Tool Owner is retiring the tool.

## Ticket type: CSV vs CSV ML

Per SOP 3.1 there are **two** ticket types, and they classify differently:

| | Ticket type | Classified by | Validation effort |
|---|---|---|---|
| Standard software | `CSV` | **SW Category** (SOP Table 1) | SOP Table 4 |
| Machine learning tools | `CSV ML` | **Level of customization** (SOP Table 2) | SOP Table 5 |

Per the SOP: "In general, Pipelines and ML libraries should be represented with the ticket type
*CSV ML*."

The field IDs in `references/field-mappings.md` were captured from **`CSV` tickets (issue type
10029)**. Before editing a `CSV ML` ticket, discover its fields with
`getJiraIssueTypeMetaWithFields` — do **not** assume the `CSV` field IDs carry over, and never
guess a custom field ID.

## Required input

The user must provide a **Jira ticket URL** for the tool being validated, e.g.:
`https://aignx.atlassian.net/browse/QM-2819`

If the user has not provided a URL, ask for it before doing anything else:
> "Please share the Jira ticket URL for the tool you'd like to validate."

Extract the issue key from the URL (e.g. `QM-2819`) and immediately call `getJiraIssue` to fetch
the current ticket state. Use the status to determine which flow applies:
- Status *New CSV* or *evaluate* → **Flow A**
- Status *Analyse risks*, *Plan Validation*, *Validation*, *Ready for approval* → **Flow A**
  (pick up from where it left off)
- Status *Tool approved* or *Monitoring* → **Flow B**
- Status *Tool rejected* → the tool failed validation and must be decommissioned → **Flow C**
- Status *Decommissioned* → terminal; nothing to do. Tell the user and stop.
- Status *On Hold* → validation is paused. Only the Risk Manager (Process Owner of TI-SOP-01) may
  set or clear this. Do not transition it yourself — tell the user who to ask.

**Check the monitoring due date immediately.** Read `customfield_10070` (Date of next
validation/monitoring). If it is in the past, the ticket is overdue — say so explicitly and treat
it as urgent. Being late into *Monitoring* is an audited defect: internal audit 2025-11-19 raised
finding **IP 1 "Unclear Monitoring Dates"** against QM-1717 for entering *Monitoring* just three
days after its due date.

---

## Flow A — New CSV Validation

### Step 1: Gather information

Ask the user these questions (only ask what isn't already clear from context):

1. **Tool name and URL/docs** — helps generate the tool description
2. **Is it cloud/SaaS or self-hosted?** — determines version field and cloud-based flag
3. **Version** — for SaaS/cloud tools, set to `"SaaS (<provider>, vendor-managed)"` (e.g.
   `"SaaS (GitHub.com, vendor-managed)"`); for on-prem tools, the specific version/tag/SHA
4. **What is it used for at Aignostics?** — purpose/context, which SOPs it touches
5. **Is it an ML tool or standard software?** — determines the **ticket type** (`CSV` vs `CSV ML`),
   and with it whether the tool is classified by SW Category or by Level of customization. If the
   ticket type does not match the answer, stop and tell the user — the ticket type drives which
   fields and which validation-effort table apply, and changing it is the Risk Manager's call.
6. **Does it influence product quality/safety, QMS documentation, or neither?** — QM-relevance
7. **Are there specific tool requirements to enforce?** — known configuration requirements,
   integrations (e.g. Okta SSO), or policies. If any are not yet implemented, flag them for
   follow-up tickets.
8. **Who is the approver?** — look up the account ID via `lookupJiraAccountId`

### Step 2: Determine classification

Use the answers to set these fields. See `references/field-mappings.md` for all Jira field IDs and
option IDs.

**SW Category / CSV Category** (standard tools):
- Non-configurable OTS → used as-is, minimal settings (e.g. viewers, browsers)
- Configurable OTS → intended to be configured for specific needs (e.g. GitHub, Jira, Confluence)
- Self-developed → built in-house or commissioned

**QM-relevance**:
- `influences product quality/safety` → training pipelines, deployment systems, test frameworks
- `influences creation and storage of records/documents for QMS or product certification` →
  Confluence, Jira, GitHub, Ketryx
- `no QM-relevance` → if neither applies; if so, ticket can go directly to *Ready for approval*

**Criticality** (drives monitoring interval and validation effort):
- High → direct regulatory/product impact (release management, V&V evidence generation)
- Moderate → disrupts QMS processes but has review workflows/backup (GitHub, Jira, Confluence)
- Low → minimal QMS impact (project management tools, dev utilities)

**Validation effort** (from Criticality + SW Category — see Table 4 in field-mappings.md):
- Justification → tool is well-established; no test sub-tasks needed
- Validation tests in context of use → self-developed or High criticality tools; requires CSV Test
  sub-tasks

### Step 3: Write field content

Generate content for all text fields (tool description, purpose/context, risks, requirements,
validation method, validation result). Use ADF format for all textarea fields — see
`references/field-mappings.md` for the ADF wrapper pattern.

**Tool requirements**: Only include requirements that reflect the actual configuration at
Aignostics. If the user confirms a feature is configured (e.g. branch protection via GitHub,
SSO via Okta), include it. If a requirement is not yet implemented, include it in the ticket AND
create a follow-up Task ticket to implement it.

**Validation result for Justification**: State that the tool is widely adopted, reference any
vendor compliance certifications (SOC 2, ISO 27001, etc.), and conclude that no additional
testing is required.

### Step 4: Write to Jira

Use `editJiraIssue` with `contentFormat: "adf"`. Set all fields in a single call:
- Tool description, Purpose/Context of Usage, QM-relevance, CSV Category, SW Category,
  Cloud based, Criticality, Version, Risks of faulty tool, Tool Requirements,
  Validation Method, Validation result, Tool Owner (Fabian's accountId: `61dff11c567cb700704ea062`),
  Approver (look up via `lookupJiraAccountId`)

See `references/field-mappings.md` for the exact field keys and option IDs.

### Step 5: Create follow-up tickets

For each tool requirement that is not yet implemented, create a separate Task in the QM project
with:
- Summary: `[Tool name]: [Short description of what needs to be configured/enforced]`
- Description: Context (link to CSV ticket), specific actions required, acceptance criteria
- Assign to Fabian (`61dff11c567cb700704ea062`)
- Link back to the CSV ticket using `createIssueLink`: inwardIssue = CSV ticket ("is blocked by"),
  outwardIssue = follow-up task ("blocks"), type = "Blocker"

### Step 6: Workflow transitions

Use `getTransitionsForJiraIssue` to find current available transitions — transition names vary
slightly. The expected sequence is:

1. *New CSV* → *evaluate* (once tool description + version filled)
2. *evaluate* → *Analyse risks* (once QM-relevance, SW category, criticality filled)
3. *Analyse risks* → *Plan Validation* (once risks + validation plan filled)
4. *Plan Validation* → *Validation* — **this is the Approver's action**, not the Tool Owner's;
   remind the user to ask the approver to make this transition
5. *Validation* → *Ready for approval* (once validation result documented; Tool Owner does this)
6. *Ready for approval* → *Tool approved* (or *Tool rejected*) — **Risk Manager's action**
7. *Tool approved* → *Monitoring* (Tool Owner sets this to begin monitoring phase)

Advance the ticket through steps 1–3 immediately after writing the fields.
For step 4, tell the user: "Please ask [Approver name] to review the plan in Jira and transition
the ticket from *Plan Validation* to *Validation*."

**Do not leave the ticket parked in *Ready for approval* silently.** Per SOP 1.4 the process KPI
counts a tool as having valid validation status **only** in *Tool Approved* or *Monitoring*; the
target is >90% and the 2026-03-11 Management Review recorded 86% (56 of 65). A ticket waiting on
the Risk Manager counts against that number, so always name the person who has to act next and
tell the user to chase it.

### Step 7: Notify #ops (Slack channel C047X4UDNHM)

After creating follow-up tickets, post a brief message to #ops summarising:
- What CSV ticket was filled (link)
- Any follow-up tickets created (with links and a one-line description)

Use `slack_send_message` — if rejected by permissions, provide the draft message for the user
to send manually.

---

## Flow B — Re-evaluation / Monitoring

### When this applies

The user mentions a CSV ticket that is already *Tool approved* or *Monitoring*, and either:
- The next monitoring date is approaching/due
- A change event occurred (new features, requirement change, tool misbehaviour, major version bump)
- The user explicitly says "re-evaluate" or "monitoring is due"

### Step 1: Fetch the ticket

Use `getJiraIssue` to read the current state: existing requirements, last validation result,
criticality, and monitoring date.

### Step 2: Do the monitoring work, then ask the user

Per SOP 3.7 monitoring is performed "based on release note checks and/or experience/tests made
during usage of the tool". **Do the release-note check yourself before asking the user anything** —
arriving with the evidence is the point of the step:

- Read the ticket's *Tool Requirements* so you know what the release notes have to be checked
  *against*. A release note only matters here if it touches a defined requirement.
- Fetch the vendor's release notes / changelog for every version between the recorded version and
  the currently deployed one (`WebFetch`/`WebSearch`).
- Where possible, confirm the actually-deployed version from the repo or cluster rather than
  trusting the ticket's Version field — it records the last monitoring round, not reality.
- Summarise for the user what changed and whether any of it touches a defined requirement.

Then ask the user:

1. **What has changed since the last validation?** (new features, config changes, incidents)
2. **Does the tool still meet all defined requirements?**
3. **Have any new risks emerged?**
4. **Is re-validation needed, or is monitoring sufficient?**

Re-validation is needed if:
- An update introduced new functions that affect the requirements
- Tool requirements have changed
- Tool behaved incorrectly
- A major code/config change occurred

A **major version bump is a prompt to check, not an automatic trigger** — the SOP's test is whether
new functions influence the *requirements*. If the tool crossed a major version boundary and the
user judges no re-validation is needed, that is a legitimate call (there is precedent across
several tickets), but record the version range explicitly in the monitoring comment so an auditor
can see it was considered rather than missed.

If only monitoring is needed (no changes, requirements still met), skip to Step 4.

### Step 3: If re-validation needed

Append a row to `customfield_10207` (Monitoring of CSV Tool) documenting the re-validation trigger
(see Step 4 for row format) and set `customfield_10069` (Date of last validation/monitoring) to
today's date **before** transitioning.

Then move the ticket to *evaluate* and run Flow A from Step 2, preserving existing content that
hasn't changed and updating only what's new. From *Monitoring* the transition to *evaluate* is
named **"Updates required"** — if the ticket is still in *Tool Approved*, take "start monitoring"
first (see the transition map in Step 5).

### Step 4: Document monitoring result

Append a new row to the existing monitoring table in `customfield_10207` — **do not overwrite
the field**; read the current ADF content first and add the new row to the existing table,
reproducing every prior row verbatim.
Each row must contain:
- Date of monitoring (today)
- Evaluation: requirements fulfilled? / new risk? / re-validation necessary?
- Comment: what was checked and the rationale for the decision

Write what you actually checked (e.g. "reviewed release notes 17.11→18.11 against the nine defined
tool requirements"), not a generic "nothing changed". The comment is the audit evidence that
monitoring happened.

Update `customfield_10069` (Date of last validation/monitoring) to today's date.

### Step 5: Transition — via *Monitoring*, not directly

Per SOP 3.7 the monitoring activity **starts** by setting the ticket to *Monitoring*; only after
the result is documented does it go to *Ready for approval*. There is no direct
*Tool Approved* → *Ready for approval* transition, and attempting one will fail.

From *Tool Approved* (verified transition IDs on the QM board):

| From | Transition | ID | To |
|---|---|---|---|
| Tool Approved | `start monitoring ` | **161** | Monitoring |
| Monitoring | `Still compliant` | **171** | Ready for approval |
| Monitoring | `Updates required` | **191** | evaluate (re-validation) |

Always call `getTransitionsForJiraIssue` to confirm — but match on **id, not name**: some
transition names carry a trailing space (`"start monitoring "`).

Then inform the user the Risk Manager approves *Ready for approval* → *Tool approved*. If the tool
no longer fulfils its requirements the Risk Manager sets *Tool rejected* instead, and the Tool
Owner initiates decommissioning (Flow C).

### Step 6: Verify the next monitoring date

`customfield_10070` (Date of next validation/monitoring) is filled automatically, but **not until
the Risk Manager transitions the ticket to *Tool approved***. It does **not** update when you set
`customfield_10069`, nor on the *Ready for approval* transition — so seeing the old date while the
ticket sits in *Ready for approval* is expected, not a bug. Do not "fix" it by hand at that point.

Verify it *after* approval: it should equal the last-monitoring date plus the Table 6 interval
(e.g. moderate + not cloud-based → +6 months; moderate + cloud-based → +3 months). Only if it is
still wrong once the ticket reaches *Tool approved* does it need manual correction — a stale date
leaves the ticket reporting as overdue and reproduces internal-audit finding IP 1.

### Monitoring intervals (for context)

| Criticality / Characteristic | Interval |
|-------------------------------|----------|
| High | Every 3 months |
| Moderate | Every 6 months |
| Low | 1 year |
| Cloud-based High/Moderate | Every 3 months |
| Cloud-based Low | Every 6 months |
| Self-developed ML tools | Every 6 months |
| Not QM-relevant | 1 year |

Cloud-based beats plain criticality: a cloud-based Moderate tool is monitored every 3 months, not
6. Check `customfield_10205` (Cloud based) before computing the interval. Earlier revalidation is
always allowed if a major change warrants it. For tools assessed as not QM-relevant, the annual
check is a re-check that the "not QM-relevant" assessment is still correct.

---

## Flow C — Decommissioning (SOP 3.8)

Applies when the Tool Owner decides to retire a tool, or when the Risk Manager has set
*Tool rejected* because the tool no longer fulfils its requirements.

1. **Set the ticket status to *Monitoring*** — per SOP 3.8 decommissioning starts from
   *Monitoring*, the same entry point as a monitoring round.
2. **Assess and document the impact of decommissioning in the ticket**: what depends on the tool,
   what records live in it, what replaces it, and whether data migration is required. If migration
   is needed, the Tool Owner initiates it.
3. **Create a ticket on the ICM board** and hand the decommissioning tasks to the appropriate team.
   Link it to the CSV ticket.
4. **Once the tool is removed or access is gone**, set the status to *Decommissioned*.

Validation records must be retained per the QMS records-retention policy — **do not delete the
ticket or clear its fields**. *Decommissioned* is the terminal state and the record stays.

---

## Important notes

- **Version for SaaS tools**: Always set to `"SaaS (<domain>, vendor-managed)"`. The SOP 3.2 Note
  makes the version optional for vendor-managed SaaS ("static version tracking is neither
  enforceable nor meaningful"), and internal audit finding IP 3 accepted that reasoning — but an
  explicit string beats an empty field, because a blank Version is indistinguishable from an
  oversight. Compliance for these tools rests on the monitoring interval instead.
- **ADF format**: All textarea fields require ADF JSON, not plain text. See field-mappings.md.
- **Honest requirements**: Only include tool requirements you can confirm are actually configured
  at Aignostics. When uncertain, ask the user explicitly.
- **Cascading select**: `customfield_10212` (CSV Category) requires a parent + child structure.
  See field-mappings.md for the exact JSON format. It is frequently left empty on older tickets —
  check it, and offer to fill it consistently with the SW Category already recorded.
- **Fill gaps you find, but say so**: when a monitoring round exposes an empty or stale field on an
  older ticket, fix it and note the correction in the monitoring row rather than fixing it
  silently. Silent edits to a controlled QM record are worse than the gap.
- **Never invent field IDs, option IDs, or SOP content.** If a needed ID isn't in
  field-mappings.md, discover it via `getJiraIssueTypeMetaWithFields` or read the SOP. A wrong
  option ID writes a wrong classification into an audited record.

## Reference files

- `references/field-mappings.md` — All Jira field keys, option IDs, SOP tables (validation
  effort, criticality definitions), and the ADF wrapper template. Read this before calling
  `editJiraIssue`.

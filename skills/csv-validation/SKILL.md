---
name: csv-validation
description: >
  Fills out and manages Computerized System Validation (CSV) Jira tickets in the QM project
  at Aignostics, following TI-SOP-01. Use this skill whenever the user wants to:
  - Validate a new software tool (fill out a QM CSV ticket from scratch)
  - Perform a re-evaluation or periodic monitoring of an already-approved tool
  - Transition a CSV ticket through its workflow steps
  - Create follow-up tickets for unmet tool requirements
  Trigger phrases: "fill out CSV ticket", "validate [tool name]", "CSV for [tool]",
  "re-evaluate [tool]", "monitoring due for [tool]", "do the CSV process", "github CSV",
  "tool validation", "QM-XXXX monitoring".
---

# CSV Validation Skill

This skill automates filling out Computerized System Validation (CSV) tickets in Jira (QM project)
following Aignostics' **TI-SOP-01**. Two distinct workflows are supported:

- **Flow A – New CSV**: A fresh ticket exists (status: *New CSV* or *evaluate*) and needs to be
  fully populated through to *Ready for approval*.
- **Flow B – Re-evaluation / Monitoring**: An existing *Tool approved* or *Monitoring* ticket is
  due for its periodic check, or a change event has triggered re-evaluation.

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

---

## Flow A — New CSV Validation

### Step 1: Gather information

Ask the user these questions (only ask what isn't already clear from context):

1. **Tool name and URL/docs** — helps generate the tool description
2. **Is it cloud/SaaS or self-hosted?** — determines version field and cloud-based flag
3. **Version** — for SaaS/cloud tools, set to `"SaaS (<provider>, vendor-managed)"` (e.g.
   `"SaaS (GitHub.com, vendor-managed)"`); for on-prem tools, the specific version/tag/SHA
4. **What is it used for at Aignostics?** — purpose/context, which SOPs it touches
5. **Is it an ML tool or standard software?** — determines CSV Category
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
6. *Ready for approval* → *Tool approved* — **Risk Manager's action**
7. *Tool approved* → *Monitoring* (Tool Owner sets this to begin monitoring phase)

Advance the ticket through steps 1–3 immediately after writing the fields.
For step 4, tell the user: "Please ask [Approver name] to review the plan in Jira and transition
the ticket from *Plan Validation* to *Validation*."

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

### Step 2: Ask the user

1. **What has changed since the last validation?** (new features, config changes, incidents)
2. **Does the tool still meet all defined requirements?**
3. **Have any new risks emerged?**
4. **Is re-validation needed, or is monitoring sufficient?**

Re-validation is needed if:
- An update introduced new functions that affect the requirements
- Tool requirements have changed
- Tool behaved incorrectly
- A major code/config change occurred

If only monitoring is needed (no changes, requirements still met), skip to Step 4.

### Step 3: If re-validation needed

Set the ticket status back to *evaluate* (via `transitionJiraIssue`) and run Flow A from Step 2,
preserving existing content that hasn't changed and updating only what's new.

Before advancing the ticket, also append a row to `customfield_10207` (Monitoring of CSV Tool)
documenting the re-validation trigger (see Step 4 for row format). Set
`customfield_10069` (Date of last validation/monitoring) to today's date.

### Step 4: Document monitoring result

Append a new row to the existing monitoring table in `customfield_10207` — **do not overwrite
the field**; read the current ADF content first and add the new row to the existing table.
Each row must contain:
- Date of monitoring (today)
- Evaluation: requirements fulfilled? / new risk? / re-validation necessary?
- Comment: what was checked and the rationale for the decision

Update `customfield_10069` (Date of last validation/monitoring) to today's date.

Transition to *Ready for approval*, then inform the user the Risk Manager needs to approve.

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

---

## Important notes

- **Version for SaaS tools**: Always set to `"SaaS (<domain>, vendor-managed)"`. Do not leave
  blank even though the SOP says it's optional — it makes the ticket clearer.
- **ADF format**: All textarea fields require ADF JSON, not plain text. See field-mappings.md.
- **Honest requirements**: Only include tool requirements you can confirm are actually configured
  at Aignostics. When uncertain, ask the user explicitly.
- **Cascading select**: `customfield_10212` (CSV Category) requires a parent + child structure.
  See field-mappings.md for the exact JSON format.

## Reference files

- `references/field-mappings.md` — All Jira field keys, option IDs, SOP tables (validation
  effort, criticality definitions), and the ADF wrapper template. Read this before calling
  `editJiraIssue`.

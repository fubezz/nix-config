# CSV Validation — Jira Field Mappings & SOP Reference

Tables 4/5/6 and the criticality guide below are condensed from TI-SOP-01. The SOP is
authoritative; when they disagree, the SOP wins:
<https://aignx.atlassian.net/wiki/spaces/QMS/pages/1993441350/TI-SOP-01+Computerized+System+Validation>

## ADF Wrapper Template

All textarea fields require Atlassian Document Format (ADF). Use `contentFormat: "adf"` in
`editJiraIssue`. Wrap plain text like this:

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "paragraph",
      "content": [{ "type": "text", "text": "Your text here" }]
    }
  ]
}
```

Ordered list:
```json
{
  "version": 1, "type": "doc",
  "content": [{
    "type": "orderedList",
    "content": [{
      "type": "listItem",
      "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Item 1" }] }]
    }]
  }]
}
```

Bullet list: same as orderedList but type is `"bulletList"`.

---

## Jira Field Reference (QM project, CSV issue type 10029)

**These IDs are for the `CSV` issue type (10029) only.** ML tools use the separate `CSV ML` issue
type, which classifies by *Level of customization* rather than *SW Category*. Discover its fields
with `getJiraIssueTypeMetaWithFields` before writing — do not reuse the IDs below on a `CSV ML`
ticket, and never guess a field or option ID.

QM site cloudId: `fff788d2-8a2a-4c36-a884-dde2bb4a2b49`

| Field Name | Field Key | Type | Notes |
|---|---|---|---|
| Tool description | `customfield_10065` | textarea (ADF) | General description of the tool |
| Purpose/Context of Usage | `customfield_10066` | textarea (ADF) | Which SOPs, tasks, environments |
| QM-relevance | `customfield_10196` | multicheckbox | See option IDs below |
| CSV Category | `customfield_10212` | cascading select | See structure below |
| SW Category | `customfield_10072` | radio button | See option IDs below |
| Cloud based | `customfield_10205` | select | yes / no |
| Criticality | `customfield_10067` | select | high / moderate / low |
| Version | `customfield_10202` | textfield | Plain string |
| Risks of faulty tool | `customfield_10194` | textarea (ADF) | |
| Tool Requirements | `customfield_10197` | textarea (ADF) | |
| Validation Method | `customfield_10213` | textarea (ADF) | |
| Validation result | `customfield_10214` | textarea (ADF) | |
| Test Specification | `customfield_10232` | textarea (ADF) | Only for test-based validation |
| Validation Effort | `customfield_10200` | readonly | Auto-calculated by Jira |
| Tool Owner | `customfield_10201` | userpicker | `{"accountId": "..."}` |
| Approver | `customfield_10220` | userpicker | `{"accountId": "..."}` |
| Monitoring of CSV Tool | `customfield_10207` | textarea (ADF) | Flow B only |
| Date of last validation/monitoring | `customfield_10069` | date | Format: YYYY-MM-DD |
| Date of next validation/monitoring | `customfield_10070` | date | Auto-set, but only on *Tool approved* |

`customfield_10070` is filled automatically as SOP 3.7.1 says, but the recalculation happens **on
the Risk Manager's transition to *Tool approved***, not before. It does not move when
`customfield_10069` is set, nor on the *Ready for approval* transition — a stale value while the
ticket awaits approval is expected and must **not** be hand-edited.

Verify after approval: expected value = date of last monitoring + the Table 6 interval. Observed
working correctly (QM-823: 2026-08-04 + 6 months → 2027-02-04, moderate/not cloud-based). Only a
value still wrong once the ticket is in *Tool approved* needs manual correction — that is the
condition behind internal-audit finding IP 1 ("Unclear Monitoring Dates", 2025-11-19).

---

## Option IDs

### QM-relevance (`customfield_10196`) — multicheckbox, set as array

```json
[{"id": "10219"}]  // influences product quality/safety
[{"id": "10220"}]  // influences creation and storage of records/documents for QMS or product certification
[{"id": "10218"}]  // no QM-relevance
// Combine: [{"id": "10219"}, {"id": "10220"}]
```

### CSV Category (`customfield_10212`) — cascading select

```json
// Standard tool → Non-configurable off-the-shelf software
{"id": "10242", "child": {"id": "10244"}}

// Standard tool → Configurable off-the-shelf software
{"id": "10242", "child": {"id": "10245"}}

// Standard tool → Self-developed software
{"id": "10242", "child": {"id": "10246"}}

// ML tool → Common
{"id": "10243", "child": {"id": "10247"}}

// ML tool → Publicly Known
{"id": "10243", "child": {"id": "10248"}}

// ML tool → Proprietary
{"id": "10243", "child": {"id": "10249"}}
```

### SW Category (`customfield_10072`) — radio button

```json
{"id": "10079"}  // Non-configurable OTS software
{"id": "10080"}  // Configurable OTS software
{"id": "10081"}  // Self-developed software
```

### Cloud based (`customfield_10205`)

```json
{"id": "10231"}  // yes
{"id": "10232"}  // no
```

### Criticality (`customfield_10067`)

```json
{"id": "10074"}  // high
{"id": "10075"}  // moderate
{"id": "10076"}  // low
```

---

## Known Account IDs

| Person | Account ID |
|---|---|
| Fabian Spieß (Tool Owner, you) | `61dff11c567cb700704ea062` |
| Nicole Hollauf | `62b473e1b065974c3e255642` |

For anyone else, use `lookupJiraAccountId` with their first name or email.

---

## Issue Link Types (for linking follow-up tickets to CSV tickets)

Use `createIssueLink` with these parameters:
- `inwardIssue`: the CSV ticket (e.g. QM-2819) — "is blocked by"
- `outwardIssue`: the follow-up task (e.g. QM-2820) — "blocks"
- `type`: `"Blocker"`

This makes the CSV ticket show *"is blocked by QM-XXXX"*, which correctly reflects that
the CSV cannot be fully closed until the follow-up is resolved.

---

## Slack Channels

| Channel | ID |
|---|---|
| #ops | `C047X4UDNHM` |

---

## Table 4: Validation Effort — Standard Tools

| | Low criticality | Moderate criticality | High criticality |
|---|---|---|---|
| Non-configurable OTS | Justification | Justification | Validation tests |
| Configurable OTS | Justification | Justification | Validation tests |
| Self-developed | Validation tests | Validation tests | Validation tests |

**Justification**: Tool is well-established; document rationale based on market adoption. No
CSV Test sub-tasks needed. Document result directly in `customfield_10214`.

**Validation tests in context of use**: Create `CSV Test` sub-tasks (one per requirement or
logical group). Reference existing supplier test docs where available.

---

## Table 5: Validation Effort — ML Tools

| | Low | Moderate | High |
|---|---|---|---|
| Common | Justification + Scientific Literature Review | Justification + Scientific Literature Review | Justification + Scientific Literature Review |
| Publicly Known | Justification + Scientific Literature Review | Expert Opinion + Random Visual Inspection + Code Review | Expert Opinion + Random Visual Inspection + Code Review |
| Proprietary | Expert Opinion + Random Visual Inspection + Code Review | Software Testing + Systematic Visual Inspection + Code Review | Software Testing + Systematic Visual Inspection + Code Review |

---

## Table 6: Monitoring Intervals

| Criticality / Characteristic | Interval |
|---|---|
| High | Every 3 months |
| Moderate | Every 6 months |
| Low | 1 year |
| Cloud-based High/Moderate | Every 3 months |
| Cloud-based Low | Every 6 months |
| Self-developed ML tools | Every 6 months |
| Not QM-relevant | 1 year |

---

## Workflow Status Sequence

```
New CSV → evaluate → Analyse risks → Plan Validation
  → Validation (Approver transitions this)
  → Ready for approval
  → Tool approved (Risk Manager transitions this)     ─┐
  → Monitoring                                         │ monitoring loop
  → Ready for approval → Tool approved                ─┘
  → Tool rejected (Risk Manager, if requirements no longer met) → decommission
  → Decommissioned (terminal; records retained)
```

### Monitoring loop — verified transition IDs

A monitoring round **always** enters through *Monitoring*. There is no direct
*Tool Approved* → *Ready for approval* transition; attempting one fails.

| From | Transition name | ID | To |
|---|---|---|---|
| Tool Approved | `start monitoring ` (trailing space) | **161** | Monitoring |
| Monitoring | `Still compliant` | **171** | Ready for approval |
| Monitoring | `Updates required` | **191** | evaluate (re-validation) |

Always call `getTransitionsForJiraIssue` first, and **match on `id`, not `name`** — at least one
name carries a trailing space. The IDs above are stable for the QM CSV workflow; they were
verified against a live ticket.

**On Hold**: Can only be set by the Process Owner of TI-SOP-01 (Risk Manager). Per SOP section 2
it is used when development is still in progress or validation is paused by external dependencies
or resource constraints, and the reason must be documented in the ticket comments. Do not set or
clear it yourself.

### Decommissioning (SOP 3.8)

Entry point is *Monitoring*, not a direct jump: set the ticket to *Monitoring*, document the
impact assessment and any data migration, create a ticket on the **ICM board** for the
decommissioning tasks, then set *Decommissioned* once the tool is removed or access is gone.
Validation records are retained — never delete the ticket or blank its fields.

---

## Criticality Decision Guide

**High** — Ask: Could failure directly affect regulatory submissions, final product quality, or
generate V&V evidence?
- Examples: algorithm deployment, model training pipelines, release management systems,
  software testing frameworks that produce V&V evidence

**Moderate** — Ask: Could failure disrupt QMS processes but are there review workflows and
backup procedures?
- Examples: GitHub, Jira, Confluence, Ketryx, CI pipelines with approval gates,
  ML experiment tracking with review processes

**Low** — Ask: Would failure cause minimal impact on regulatory compliance or product quality?
- Examples: communication tools, general dev environments, project management tools,
  general cloud storage for non-critical data, ML libraries (Common level)

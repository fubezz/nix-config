---
name: interview
argument-hint: [topic]
description: Conduct a structured reverse interview for standalone topic research — produces annotated transcript + summary pair. Use when user says "/interview <topic>", "interview me about X", or wants to explore a topic through structured Q&A.
allowed-tools: Read, Write, Glob, Grep, AskUserQuestion
---

# Interview Command

Use `/interview <topic>` to conduct a comprehensive reverse interview as standalone topic research.

**Features:**
- Dynamic question generation (2-42 questions based on complexity)
- Adaptive follow-ups and progressive questioning
- Output split into two files under `.local/interviews/YYYY-MM-DD/<topic>/`:
  - `transcript.md` — chronological Q&A with annotations
  - `summary.md` — themes, insights, conclusions; references the transcript
- Keeps main context clean during interview process

**Usage:** `/interview "product feature requirements"` or `/interview microservice-architecture`

---

# Task Description
Conduct comprehensive topic exploration through structured reverse interviews that produce two separate documents: an annotated transcript and a summary with insights and conclusions.

## Input/Context Section
$ARGUMENTS

## Instructions for general-purpose Agent
You are an expert Interview Agent specializing in comprehensive topic exploration through structured reverse interviews. Your primary goal is to conduct thorough, adaptive interviews that produce actionable insights and detailed documentation.

## Core Process

### 1. Interview Initialization

1. **Analyze topic complexity** and determine appropriate question count (2-42)
2. **Research the codebase first**: Before generating questions, use `Read` and `Glob` tools to explore relevant parts of the codebase. Do NOT ask the user questions you can answer yourself by reading the code — questions about current architecture, file structure, existing implementations, dependencies, or configuration. Reserve interview questions for things only the user knows: goals, priorities, constraints, preferences, trade-offs, and business context.
3. **Generate ordered question set**: fundamental → supplementary → edge cases
4. **Create output directory** if needed (`.local/interviews/YYYY-MM-DD/<topic>/`)
5. **Present your understanding**: Before asking the first question, write in your own words how you understand the goal and purpose of this interview. Then use `AskUserQuestion` to ask whether the user wants to discuss/refine this formulation or proceed as-is:
   ```
   AskUserQuestion({
     questions: [{
       question: "[Your understanding of the interview goal]\n\nReady to proceed, or want to refine the goal first?",
       header: "Interview goal",
       multiSelect: false,
       options: [
         { label: "Looks good, let's start", description: "Goal is accurate, proceed to questions" },
         { label: "Need to adjust", description: "Want to refine the goal or add context first" }
       ]
     }]
   })
   ```
   If the user wants to refine — discuss until alignment is reached, then proceed.
6. **Announce session**: *"I've prepared [N] questions to explore [topic]. Let's begin."*

### 2. Interactive Interview Flow

For each question, use the `AskUserQuestion` tool to present the question along with 2-4 suggested answer options. Always enable `multiSelect: true` so the user can select one or several suggestions, or choose "Other" (automatically provided) to type a custom reply.

**How to craft suggested options:**
- Based on the topic and prior answers, generate 2-4 plausible/common answers as options
- Each option label should be concise (1-5 words), with a description expanding on what it means
- Options should cover distinct perspectives or approaches relevant to the question
- Use the `header` field as a short tag for the question theme (e.g., "Scope", "Priority", "Users")

**Example:**
```
AskUserQuestion({
  questions: [{
    question: "[Q2/10] Who is the primary target audience for this feature?",
    header: "Audience",
    multiSelect: true,
    options: [
      { label: "Internal team", description: "Used by developers or internal stakeholders only" },
      { label: "End users", description: "Customer-facing feature for external users" },
      { label: "API consumers", description: "Third-party developers integrating via API" }
    ]
  }]
})
```

**Processing user responses:**
- If user selects one or more suggestions → combine them into the response context
- If user selects "Other" and provides custom text → use that as the primary response
- If user selects suggestions AND adds custom text → merge both into a richer response

**Evaluation Logic (after receiving answer):**
- **Complete answer** → proceed to next question
- **Needs clarity** → ask a follow-up using `AskUserQuestion` with refined options: *"Follow-up [1]: ..."*
- **Surface-level** → request elaboration with targeted options
- **Reveals new complexity** → adapt remaining questions

**Dynamic Adaptation:**
- Modify/skip upcoming questions based on responses
- Insert emergent questions for critical discoveries
- Explicitly announce adaptations: *"Based on your answer, I'm adjusting my approach..."*
- Tailor suggested options for subsequent questions based on earlier answers

### 3. Progress Management

- **Visual progress**: Update `[Q3/10] ████░░░░░░` after each question
- **Milestone markers**: Show completion percentage at 50%+ (*"[60% Complete]"*)
- **Section breaks**: Use `━━━━━━━━━━` between questions
- **Session persistence**: Track state for potential resume capability

### 4. Output Generation

Create two files under `.local/interviews/YYYY-MM-DD/<topic>/`:

#### 4.1 `transcript.md` — Chronological Q&A with annotations

Standard header:
```markdown
---
Generated: YYYY-MM-DD HH:MM
Type: interview-transcript
Topic: [topic name]
Status: transcript
Companion: ./summary.md
---
```

**Format**: Each Q&A as its own section, with a stable anchor for cross-referencing from the summary.

```markdown
## Question 1: [Question text] {#q1}

**User Response:**
[Complete user answer]

**Agent Observations:**
- [Key insight or pattern noticed]
- [Connection to other responses]
- [Technical implications]

**Follow-up 1:** [If applicable]
[User's follow-up answer]

---

## Question 2: [Question text] {#q2}
...
```

The transcript contains ONLY the chronological dialogue and annotations — no summary, no insights section, no recommendations.

#### 4.2 `summary.md` — Themes, insights, conclusions

Standard header:
```markdown
---
Generated: YYYY-MM-DD HH:MM
Type: interview-summary
Topic: [topic name]
Status: summary
Transcript: ./transcript.md
---

# [Topic] — Interview Summary

> 📜 Full conversation: [transcript.md](./transcript.md)
```

**Required sections:**

##### Interview Overview
- **Topic**: Clear description of interview focus
- **Questions Asked**: Total number (including follow-ups)
- **Complexity Assessment**: Simple / Moderate / Complex / Highly Complex
- **Interview Duration**: Approximate time span

##### Key Insights & Conclusions

Organize discovered insights by theme. Reference specific Q&As in the transcript via anchor links:

**Theme 1: [Name]**
- Insight: [What was learned]
- Evidence: [`Q3`](./transcript.md#q3), [`Q7`](./transcript.md#q7)
- Implications: [What this means]

**Theme 2: [Name]**
...

##### Open Questions & Ambiguities
- Questions that need further exploration
- Areas where responses were unclear or conflicting (link to specific Q&As)
- Topics that surfaced but weren't fully explored

##### Recommended Next Steps
- **For deeper research**: Areas needing additional investigation
- **For clarification**: Specific points to revisit

## Quality Standards

### Interview Conduct
- **One question at a time** - never present multiple questions simultaneously
- **Active listening** - build on previous responses naturally
- **Context bridging** - reference earlier insights: *"Building on your point about [X]..."*
- **Depth seeking** - push beyond surface-level responses appropriately

### Output Quality
- **Rich annotations** - observations and insights captured alongside responses in the transcript
- **Comprehensive coverage** - address all aspects revealed during interview
- **Cross-referencing** - summary.md MUST link back to specific Q&As in transcript.md via `./transcript.md#qN` anchors
- **Professional formatting** - clean markdown with proper headings and lists

### Adaptation Signals
| User Response | Agent Action |
|---------------|--------------|
| "skip" / "next" | Move immediately to next question |
| "wait" / "confused" | Slow down, rephrase, add context |
| "go deeper" | Expand current line of questioning |
| "big picture" | Zoom out to show broader context |

## File Management

1. **Directory creation**: Ensure `.local/interviews/YYYY-MM-DD/<topic>/` exists (create if missing)
2. **Topic sanitization**: Convert topic to safe directory name (spaces → hyphens, lowercase, remove special chars)
3. **Standard layout**: `.local/interviews/YYYY-MM-DD/<topic>/transcript.md` and `.local/interviews/YYYY-MM-DD/<topic>/summary.md`
4. **Git ignore handling**: `.local/` is already git-ignored globally

## Session Completion

When interview concludes:

```markdown
📊 **Session Summary**
- Questions asked: X of Y planned
- Follow-ups conducted: N
- Key themes discovered: [list]
- Adaptation points: [major shifts in approach]
- Output saved to:
  - `.local/interviews/YYYY-MM-DD/<topic>/summary.md`
  - `.local/interviews/YYYY-MM-DD/<topic>/transcript.md`

📜 Open the summary first; it links into specific Q&As in the transcript.
```

## Error Handling

- **Invalid topic**: Request clarification and examples
- **File write issues**: Suggest alternative locations
- **Incomplete session**: Offer resume capability with session state
- **Unclear responses**: Use structured follow-ups rather than proceeding

## Success Criteria

- **Thoroughness**: All relevant aspects of topic explored
- **Rich insights**: Key patterns, themes, and implications captured in `summary.md`
- **Traceability**: Every insight in `summary.md` traceable to a Q&A in `transcript.md` via anchor link
- **Context preservation**: Main LLM context remains uncluttered
- **Professional quality**: Output meets documentation standards for sharing/presentation

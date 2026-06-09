---
name: prd-generator
description: "Generate a Product Requirements Document (PRD) for a new feature. Supports Linear issues, projects, Figma designs, or text descriptions. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out, /prd."
---

# PRD Generator

Create detailed Product Requirements Documents that are clear, actionable, and suitable for implementation by both human developers and AI agents like Ralph.

---

## Input Sources

The PRD generator accepts multiple input types:

| Input | Example | What Happens |
|-------|---------|--------------|
| **Linear Issue** | `ENG-1234`, `PLAT-567` | Fetches issue, extracts requirements |
| **Linear Project** | `project:Calendar Filter` | Fetches project + all linked issues |
| **Figma URL** | `https://figma.com/design/...` | Extracts design specs |
| **Text Description** | `Add dark mode toggle` | Uses as feature description |
| **Interactive** | (empty) | Asks what to build |

---

## Step 1: Parse Input & Fetch Context

### Detect Input Type

```javascript
function parseInput(input) {
  // Linear issue: matches TEAM-123 pattern
  if (input.match(/^[A-Z]+-\d+$/)) {
    return { type: 'linear-issue', id: input };
  }

  // Linear project: starts with "project:"
  if (input.startsWith('project:')) {
    return { type: 'linear-project', query: input.slice(8) };
  }

  // Figma URL
  if (input.includes('figma.com')) {
    return { type: 'figma', url: input };
  }

  // Text description
  if (input.length > 0) {
    return { type: 'description', text: input };
  }

  // Interactive mode
  return { type: 'interactive' };
}
```

### Fetch from Linear Issue

When input is a Linear issue (e.g., `ENG-1234`):

```javascript
// Fetch the issue with relations
const issue = await mcp__linear__get_issue({
  id: "ENG-1234",
  includeRelations: true
});

// Extract key information
const context = {
  title: issue.title,
  description: issue.description,
  labels: issue.labels,
  state: issue.state,
  priority: issue.priority,
  attachments: issue.attachments,  // May contain Figma links
  relations: {
    blocks: issue.relations?.blocks,
    blockedBy: issue.relations?.blockedBy,
    related: issue.relations?.related
  }
};

// Fetch comments for additional context
const comments = await mcp__linear__list_comments({
  issueId: issue.id
});
```

**What to extract from the issue:**
- **Title** → Feature name
- **Description** → Requirements, acceptance criteria, context
- **Labels** → Scope hints (e.g., "frontend", "backend", "P0")
- **Attachments** → Figma links, design specs, documents
- **Comments** → Discussions, clarifications, decisions
- **Relations** → Dependencies, related work

### Fetch from Linear Project

When input is a Linear project (e.g., `project:Calendar`):

```javascript
// Find the project
const project = await mcp__linear__get_project({
  query: "Calendar Filter"
});

// Get all issues in the project
const issues = await mcp__linear__list_issues({
  project: project.id,
  limit: 50
});

// Extract project context
const context = {
  name: project.name,
  description: project.description,
  state: project.state,
  lead: project.lead,
  targetDate: project.targetDate,
  issues: issues.map(i => ({
    id: i.identifier,
    title: i.title,
    description: i.description,
    state: i.state,
    priority: i.priority
  }))
};
```

**What to extract from the project:**
- **Project description** → Overview, goals
- **Project issues** → Potential user stories (may need splitting)
- **Issue states** → What's done vs pending
- **Target date** → Timeline context

### Fetch from Figma

When input is a Figma URL:

```javascript
// Extract file key and node ID from URL
const fileKey = extractFileKey(figmaUrl);
const nodeId = extractNodeId(figmaUrl);

// Get design context
const design = await mcp__figma__get_design_context({
  fileKey,
  nodeId,
  clientLanguages: "typescript",
  clientFrameworks: "react-native"
});

// Get screenshot for reference
const screenshot = await mcp__figma__get_screenshot({
  fileKey,
  nodeId
});

// Get design tokens
const variables = await mcp__figma__get_variable_defs({
  fileKey,
  nodeId
});
```

---

## Step 2: Codebase Research (Parallel)

**Before generating the PRD, research the codebase** to understand existing patterns, identify files to modify, and discover potential risks.

### Launch Research Agents in Parallel

Use the Task tool to run multiple research agents simultaneously:

```javascript
const researchResults = await Promise.all([
  // Agent 1: Find related code
  Task({
    subagent_type: 'Explore',
    description: 'Find related code',
    prompt: `Search the codebase for code related to: ${featureDescription}

    Find:
    1. Existing similar features or patterns
    2. Files that will likely need modification
    3. Related components, services, or utilities
    4. Existing tests for similar functionality

    Return a structured list of relevant files with brief descriptions.`
  }),

  // Agent 2: Identify patterns
  Task({
    subagent_type: 'Explore',
    description: 'Identify patterns',
    prompt: `Analyze codebase patterns for: ${featureDescription}

    Look for:
    1. How similar features are structured
    2. Naming conventions used
    3. State management patterns (Zustand stores, React Query, etc.)
    4. Component patterns (where components live, how they're organized)
    5. API/GraphQL patterns

    Return patterns that should be followed for this feature.`
  }),

  // Agent 3: Check for conflicts/risks
  Task({
    subagent_type: 'Explore',
    description: 'Check for risks',
    prompt: `Identify potential risks for implementing: ${featureDescription}

    Check:
    1. Are there existing features this might conflict with?
    2. Are there shared components that might be affected?
    3. Are there performance concerns?
    4. Are there any deprecated patterns to avoid?

    Return a risk assessment with mitigation suggestions.`
  })
]);

// Synthesize research into context for PRD
const codebaseContext = {
  relatedFiles: researchResults[0],
  patterns: researchResults[1],
  risks: researchResults[2]
};
```

### What Research Provides

| Research | Output | Use In PRD |
|----------|--------|------------|
| Related code | List of files | Technical Considerations |
| Patterns | Conventions to follow | User Story details |
| Risks | Potential conflicts | Non-Goals, Technical Considerations |

### Include Research in PRD

Add a **Codebase Research** section to the generated PRD:

```markdown
## Codebase Research

### Related Files
- `member/screens/CultureCalendar.tsx` - Main calendar screen
- `member/components/Filters/` - Existing filter components
- `member/stores/calendarStore.ts` - Calendar state management

### Patterns to Follow
- Use Zustand for filter state (like `restaurantStore.ts`)
- Filter chips use `FilterChip` component from design system
- URL sync uses `useSearchParams` hook pattern

### Identified Risks
- Calendar already has date filtering - ensure category filters integrate smoothly
- Large event lists may need virtualization with filters
```

---

## Step 3: Clarifying Questions (If Needed)

**Skip or reduce questions** when context is rich (from Linear/Figma).

**Ask questions** when context is sparse (text description or interactive).

### When to Ask Questions

| Source | Questions Needed |
|--------|------------------|
| Linear issue with detailed description | 0-2 questions (fill gaps only) |
| Linear project | 1-3 questions (confirm scope) |
| Figma design | 1-2 questions (confirm behavior) |
| Text description | 3-5 questions (full discovery) |
| Interactive | 3-5 questions (full discovery) |

### Question Format

Use lettered options for quick responses:

```
Based on the Linear issue ENG-1234, I have most of the context.
A few clarifying questions:

1. The issue mentions "filtering" - should filters persist across sessions?
   A. Yes, save to user preferences
   B. No, reset on page reload
   C. Save to URL only (shareable but not persistent)

2. Should this work on mobile or just web?
   A. Mobile only
   B. Web only
   C. Both platforms
```

Users can respond: "1C, 2A"

---

## Step 4: Generate PRD

### PRD Structure

```markdown
# PRD: [Feature Name]

> **Source:** [Linear issue ENG-1234 | Linear project "Calendar" | User description]
> **Generated:** [Date]

## Introduction

[Brief description of the feature and the problem it solves]

## Goals

- [Specific, measurable objective 1]
- [Specific, measurable objective 2]

## User Stories

### US-001: [Story Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Typecheck passes
- [ ] [UI stories] Verify in browser

### US-002: [Story Title]
...

## Functional Requirements

- FR-1: The system must...
- FR-2: When a user...

## Non-Goals (Out of Scope)

- [What this feature will NOT do]

## Codebase Research

### Related Files
- [Files that will be modified]
- [Related components/services]

### Patterns to Follow
- [Conventions discovered in research]

### Identified Risks
- [Potential conflicts or issues]

## Design Considerations

- [Figma link if available]
- [UI/UX notes]
- [Existing components to reuse]

## Technical Considerations

- [Dependencies from research]
- [Integration points]
- [Performance requirements]

## Success Metrics

- [How success will be measured]

## Open Questions

- [ ] [Remaining questions]

## Source Material

### Linear Issue
- **ID:** ENG-1234
- **URL:** https://linear.app/team/issue/ENG-1234
- **Original Description:** [quoted]

### Figma Design
- **URL:** [link]
- **Screenshot:** [embedded or linked]
```

---

## Story Size: Critical for Ralph

**Each story must be completable in ONE Ralph iteration.**

### Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (split these):
- "Build the entire dashboard" → schema, queries, UI components, filters
- "Add authentication" → schema, middleware, login UI, session handling

### Splitting Linear Issues into Stories

If the Linear issue is too broad, split it:

**Linear Issue:** "Add category filtering to culture calendar"

**Split into User Stories:**
1. US-001: Add category field to events schema
2. US-002: Create GraphQL query for categories
3. US-003: Add category filter UI component
4. US-004: Integrate filter with event list
5. US-005: Persist filter selection in URL

---

## Acceptance Criteria: Must Be Verifiable

### Good (verifiable):
- "Add `status` column with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"

### Bad (vague):
- "Works correctly"
- "Good UX"
- "Handles edge cases"

### Always Include:
```
- [ ] Typecheck passes
- [ ] [UI stories] Verify in browser
```

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `tasks/`
- **Filename:** `prd-[feature-name].md` (kebab-case)

If generated from Linear issue `ENG-1234`:
- Filename: `tasks/prd-eng-1234-[feature-name].md`

---

## Example: PRD from Linear Issue

**Input:** `/prd ENG-1234`

**Linear Issue ENG-1234:**
```
Title: Add category filtering to culture calendar
Description:
Users should be able to filter events by category (music, art, food, etc.)
to find relevant events more easily.

Acceptance Criteria:
- Filter UI visible on calendar page
- Multiple categories can be selected
- Filter state persists in URL
```

**Generated PRD:**

```markdown
# PRD: Culture Calendar Category Filtering

> **Source:** Linear issue ENG-1234
> **Generated:** 2024-01-15

## Introduction

Add category filtering to the culture calendar so users can filter events
by category (music, art, food, etc.) to find relevant events more easily.

## Goals

- Allow filtering events by one or more categories
- Make filter easily accessible on the calendar page
- Persist filter state in URL for sharing/bookmarking
- Improve event discovery for users with specific interests

## User Stories

### US-001: Add category field to events
**Description:** As a developer, I need events to have categories stored.

**Acceptance Criteria:**
- [ ] Events have `categories` field (array of category IDs)
- [ ] Categories are pre-defined enum or separate collection
- [ ] Typecheck passes

### US-002: Create category filter UI component
**Description:** As a user, I want to see and interact with category filters.

**Acceptance Criteria:**
- [ ] Filter chips/buttons for each category
- [ ] Visual indication of selected categories
- [ ] "Clear all" option when filters active
- [ ] Typecheck passes
- [ ] Verify in browser

### US-003: Implement filter logic
**Description:** As a user, I want the event list to update when I filter.

**Acceptance Criteria:**
- [ ] Selecting category filters the visible events
- [ ] Multiple categories show events matching ANY selected
- [ ] Empty state when no events match
- [ ] Typecheck passes
- [ ] Verify in browser

### US-004: Persist filter in URL
**Description:** As a user, I want to share filtered views with others.

**Acceptance Criteria:**
- [ ] Selected categories reflected in URL params
- [ ] Loading URL with params pre-selects filters
- [ ] Changing filters updates URL without page reload
- [ ] Typecheck passes
- [ ] Verify in browser

## Functional Requirements

- FR-1: Display category filter UI on culture calendar page
- FR-2: Support multi-select (OR logic) for categories
- FR-3: Update event list in real-time when filters change
- FR-4: Sync filter state with URL query parameters
- FR-5: Show empty state message when no events match filters

## Non-Goals

- No saved filter preferences (beyond URL)
- No category management UI (admin only)
- No category suggestions based on user history

## Technical Considerations

- Use existing filter chip component from design system
- URL params: `?categories=music,art,food`
- Consider debouncing filter changes for performance

## Success Metrics

- Users can filter to relevant events in under 3 clicks
- Filtered URLs are shareable and work correctly
- No performance regression on calendar page

## Source Material

### Linear Issue
- **ID:** ENG-1234
- **URL:** https://linear.app/your-team/issue/ENG-1234
```

---

## Checklist

Before saving the PRD:

- [ ] Identified input source (Linear/Figma/description)
- [ ] Fetched all available context
- [ ] **Ran codebase research** (parallel agents)
- [ ] Asked clarifying questions only for gaps
- [ ] User stories are small (15-60 min each)
- [ ] Acceptance criteria are verifiable
- [ ] Non-goals define clear boundaries
- [ ] **Codebase research section included** (files, patterns, risks)
- [ ] Source material linked/quoted
- [ ] Saved to `tasks/prd-[feature-name].md`

# /prd - Create a Product Requirements Document

Generate a detailed Product Requirements Document (PRD) for a new feature. The PRD can later be converted to Ralph format for autonomous execution.

## Usage

```bash
# From a Linear issue
/prd ENG-1234                            # Fetch issue and generate PRD from it
/prd PLAT-567                            # Works with any team prefix

# From a Linear project
/prd project:Calendar Filtering          # Generate PRD from project details
/prd project:abc123-def456               # Or use project ID

# From a Figma design
/prd https://figma.com/design/abc123/MyDesign?node-id=1-2

# From text description
/prd Add dark mode toggle to settings    # Create PRD for specific feature

# Interactive mode
/prd                                      # Asks what to build
```

## Workflow

When you run `/prd`, the following happens:

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRD GENERATION                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. PARSE INPUT                                                 │
│     ├── Linear issue? → Fetch issue details via MCP            │
│     ├── Linear project? → Fetch project & linked issues        │
│     ├── Figma URL? → Extract design specs via Figma MCP        │
│     ├── Text description? → Use as feature description         │
│     └── Empty? → Ask what to build (interactive)               │
│                                                                 │
│  2. UNDERSTAND (from Linear or user input)                     │
│     ├── Extract requirements from issue description            │
│     ├── Pull acceptance criteria if present                    │
│     ├── Get linked issues/sub-tasks                            │
│     └── Note any attachments (Figma links, etc.)               │
│                                                                 │
│  3. CLARIFY (if needed, 2-4 questions)                         │
│     ├── Fill gaps not covered by Linear issue                  │
│     ├── Confirm scope boundaries                               │
│     └── Validate technical approach                            │
│                                                                 │
│  4. GENERATE PRD                                               │
│     ├── Introduction/Overview                                  │
│     ├── Goals (from Linear or clarifying questions)            │
│     ├── User Stories with Acceptance Criteria                  │
│     ├── Functional Requirements                                │
│     ├── Non-Goals (scope boundaries)                           │
│     ├── Technical Considerations                               │
│     └── Success Metrics                                        │
│                                                                 │
│  5. SAVE                                                       │
│     └── tasks/prd-[feature-name].md                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Linear Integration

When you provide a Linear issue or project, the PRD generator will:

### From a Linear Issue (e.g., `/prd ENG-1234`)

1. **Fetch the issue** using `mcp__linear__get_issue`
2. **Extract information:**
   - Title → Feature name
   - Description → Requirements, context
   - Labels → Scope hints
   - Attachments → Figma links, specs
   - Comments → Additional context
3. **Get related issues** if `includeRelations: true`
4. **Generate PRD** with pre-filled context

### From a Linear Project (e.g., `/prd project:Calendar`)

1. **Fetch the project** using `mcp__linear__get_project`
2. **List project issues** using `mcp__linear__list_issues`
3. **Extract information:**
   - Project description → Overview
   - Project issues → Potential user stories
   - Project state → Timeline context
4. **Generate PRD** encompassing the project scope

### From a Figma Design (e.g., `/prd https://figma.com/...`)

1. **Extract file key and node ID** from the URL
2. **Fetch design context** using `mcp__figma__get_design_context`
3. **Get screenshot** using `mcp__figma__get_screenshot`
4. **Extract information:**
   - Component structure → UI requirements
   - Design tokens → Styling specs
   - Layout → User flow hints
5. **Generate PRD** with embedded design reference

## Output

The PRD is saved to `tasks/prd-[feature-name].md` in markdown format.

## Next Steps

After creating a PRD:

1. **Review the PRD** - Make any adjustments needed
2. **Convert to Ralph format**:
   ```
   Load the ralph-converter skill and convert tasks/prd-[name].md to ralph/prd.json
   ```
3. **Run Ralph**:
   ```bash
   /ralph
   ```

## PRD Structure

```markdown
# PRD: [Feature Name]

## Introduction
Brief description of the feature and problem it solves.

## Goals
- Specific, measurable objectives

## User Stories

### US-001: [Story Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Verifiable criterion 1
- [ ] Verifiable criterion 2
- [ ] Typecheck passes
- [ ] [UI stories] Verify in browser

### US-002: [Story Title]
...

## Functional Requirements
- FR-1: The system must allow users to...
- FR-2: When a user clicks X, the system must...

## Non-Goals (Out of Scope)
What this feature will NOT include.

## Technical Considerations
Known constraints, dependencies, integration points.

## Success Metrics
How success will be measured.

## Open Questions
Remaining questions or areas needing clarification.
```

## Writing Good User Stories

### Right-Sized Stories

Each story should be completable in 15-60 minutes:

**Good:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

**Too Big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### Verifiable Acceptance Criteria

**Good (verifiable):**
- "Add `status` column with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"

**Bad (vague):**
- "Works correctly"
- "User can do X easily"
- "Good UX"

## Example

```bash
/prd Add task priority levels
```

Output in `tasks/prd-task-priority.md`:

```markdown
# PRD: Task Priority System

## Introduction
Add priority levels to tasks so users can focus on what matters most.

## Goals
- Allow assigning priority (high/medium/low) to any task
- Provide clear visual differentiation between priority levels
- Enable filtering by priority
- Default new tasks to medium priority

## User Stories

### US-001: Add priority field to database
**Description:** As a developer, I need to store task priority.

**Acceptance Criteria:**
- [ ] Add priority column: 'high' | 'medium' | 'low' (default 'medium')
- [ ] Generate and run migration
- [ ] Typecheck passes

### US-002: Display priority indicator on task cards
**Description:** As a user, I want to see task priority at a glance.

**Acceptance Criteria:**
- [ ] Colored priority badge (red=high, yellow=medium, gray=low)
- [ ] Priority visible without hovering
- [ ] Typecheck passes
- [ ] Verify in browser

...
```

## Related

- `/ralph` - Run the autonomous agent loop
- `prd-generator` skill - Full PRD generation details
- `ralph-converter` skill - Convert PRD to JSON

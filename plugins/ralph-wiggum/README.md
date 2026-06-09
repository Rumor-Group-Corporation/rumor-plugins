# Ralph Wiggum Plugin

> "Me fail English? That's unpossible!" - Ralph Wiggum

Ralph Wiggum is an autonomous AI agent loop that runs Claude Code repeatedly until all PRD items are complete. Each iteration is a fresh Claude instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/) and [snarktank/ralph](https://github.com/snarktank/ralph).

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                         RALPH WIGGUM LOOP                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. READ PRD                                                        │
│     └── Load prd.json with user stories                            │
│                                                                     │
│  2. CHECK PROGRESS                                                  │
│     └── Read progress.txt for learnings from previous iterations   │
│                                                                     │
│  3. PICK NEXT STORY                                                 │
│     └── Find highest priority story where passes: false            │
│                                                                     │
│  4. IMPLEMENT                                                       │
│     └── Complete the single user story                             │
│                                                                     │
│  5. QUALITY CHECKS                                                  │
│     └── Run typecheck, lint, tests                                 │
│                                                                     │
│  6. COMMIT                                                          │
│     └── If checks pass, commit changes                             │
│                                                                     │
│  7. UPDATE STATE                                                    │
│     ├── Set passes: true in prd.json                               │
│     └── Append learnings to progress.txt                           │
│                                                                     │
│  8. CHECK COMPLETION                                                │
│     ├── All stories done? → Output <promise>COMPLETE</promise>     │
│     └── Stories remaining? → End iteration (loop continues)        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Commands

### `/ralph` - Run the Ralph Loop

Starts the autonomous agent loop to complete all PRD items.

```bash
/ralph              # Start with default 10 iterations
/ralph 20           # Start with 20 max iterations
```

### `/prd` - Create a PRD

Generate a Product Requirements Document for a new feature.

```bash
/prd Add dark mode toggle to settings
/prd                # Interactive mode
```

## Workflow

### 1. Create a PRD

Use the `/prd` command to generate a detailed requirements document:

```bash
/prd Add task priority levels to the task management system
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph Format

After creating the PRD, convert it to JSON:

```
Load the ralph-converter skill and convert tasks/prd-task-priority.md to ralph/prd.json
```

This creates `ralph/prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
./plugins/ralph-wiggum/scripts/ralph.sh [max_iterations]
```

Or use the command:

```bash
/ralph 10
```

## Key Files

| File | Purpose |
|------|---------|
| `ralph/prd.json` | User stories with `passes` status (the task list) |
| `ralph/progress.txt` | Append-only learnings for future iterations |
| `ralph/archive/` | Previous run archives |

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new Claude Code instance** with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing.

**Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

**Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Ralph updates the relevant `AGENTS.md` files with learnings. This is key because Claude Code automatically reads these files, so future iterations benefit from discovered patterns.

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green

## Directory Structure

```
your-project/
├── ralph/
│   ├── prd.json         # Current PRD being executed
│   ├── progress.txt     # Learnings from iterations
│   └── archive/         # Previous runs
├── tasks/
│   └── prd-*.md         # Generated PRDs (markdown)
└── AGENTS.md            # Updated with learnings
```

## Skills

### PRD Generator

Generates detailed Product Requirements Documents with:
- Clarifying questions with lettered options
- User stories with acceptance criteria
- Functional requirements
- Non-goals / scope boundaries

### Ralph Converter

Converts markdown PRDs to the JSON format Ralph uses:
- Ensures stories are small enough
- Orders by dependencies
- Adds required fields

## Credits

- [Geoffrey Huntley](https://ghuntley.com/ralph/) - Original Ralph pattern
- [snarktank/ralph](https://github.com/snarktank/ralph) - Amp implementation

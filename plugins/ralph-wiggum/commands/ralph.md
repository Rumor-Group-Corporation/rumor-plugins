# /ralph - Run the Ralph Wiggum Agent Loop

Run the autonomous AI agent loop to complete all PRD items. Each iteration spawns a fresh Claude instance with clean context.

## Usage

```bash
/ralph              # Start with default 10 iterations
/ralph 20           # Start with 20 max iterations
```

## Prerequisites

Before running `/ralph`, you need:

1. **A `ralph/prd.json` file** - Create one using `/prd` and then convert it with the ralph-converter skill
2. **jq installed** - `brew install jq`

## What Happens

When you run `/ralph`, the following loop executes:

```
┌─────────────────────────────────────────────────────────────────┐
│                    RALPH WIGGUM LOOP                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  For each iteration until complete or max_iterations:          │
│                                                                 │
│  1. Read ralph/prd.json                                        │
│  2. Read ralph/progress.txt (learnings from past iterations)   │
│  3. Pick highest priority story where passes: false            │
│  4. Implement that ONE story                                   │
│  5. Run quality checks (typecheck, lint, test)                 │
│  6. Commit if checks pass                                      │
│  7. Update prd.json to mark story as passes: true              │
│  8. Append learnings to progress.txt                           │
│  9. If all stories done → output <promise>COMPLETE</promise>   │
│     Otherwise → end iteration, loop continues                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `ralph/prd.json` | User stories with `passes` status |
| `ralph/progress.txt` | Append-only learnings for future iterations |
| `ralph/archive/` | Previous run archives |

## Workflow

### Step 1: Create a PRD

```bash
/prd Add task priority system to the task manager
```

This generates `tasks/prd-task-priority.md`.

### Step 2: Convert to Ralph Format

```
Load the ralph-converter skill and convert tasks/prd-task-priority.md to ralph/prd.json
```

### Step 3: Run Ralph

```bash
/ralph
```

Watch as Ralph autonomously completes each user story!

## Critical Concepts

### Fresh Context Each Iteration

Each iteration is a **new Claude instance** with no memory of previous work. Memory persists only through:
- Git history (commits)
- `ralph/progress.txt` (learnings)
- `ralph/prd.json` (story status)

### Small Stories

Stories must be completable in one context window. If too big:
- The agent runs out of context
- Code quality degrades
- Stories should take 15-60 minutes

### Feedback Loops

Ralph needs feedback to know if code is correct:
- Typecheck must pass
- Lint must pass
- Tests must pass
- CI must stay green

## Stopping Ralph

- **Natural completion**: All stories have `passes: true`
- **Max iterations**: Reached the iteration limit
- **Manual stop**: Ctrl+C to interrupt

## Resuming

Ralph automatically resumes where it left off:
- Stories already marked `passes: true` are skipped
- Progress in `progress.txt` is preserved
- Just run `/ralph` again to continue

## Example Output

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🎭 RALPH WIGGUM - Autonomous Agent Loop                    ║
║                                                               ║
║   "Me fail English? That's unpossible!"                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Starting Ralph - Max iterations: 10

Current PRD Status:
  [ ] US-001: Add priority field to database
  [ ] US-002: Display priority indicator on task cards
  [ ] US-003: Add priority selector to task edit
  [ ] US-004: Filter tasks by priority

═══════════════════════════════════════════════════════════════
  Ralph Iteration 1 of 10
═══════════════════════════════════════════════════════════════

[Claude Code executes and completes US-001...]

═══════════════════════════════════════════════════════════════
  🎉 Ralph completed all tasks!
  Completed at iteration 4 of 10
═══════════════════════════════════════════════════════════════
```

## Troubleshooting

### "No prd.json found"

Create one first:
1. `/prd [your feature]`
2. Load ralph-converter skill
3. Convert the PRD to JSON

### "jq is required"

Install jq: `brew install jq`

### Stories not completing

- Check if stories are too large (split them)
- Check if tests/typecheck are failing
- Review `ralph/progress.txt` for errors

## Related

- `/prd` - Create a new PRD
- `ralph-converter` skill - Convert PRD to JSON
- `prd-generator` skill - PRD generation details

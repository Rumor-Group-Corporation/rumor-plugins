# /ralph-status - Check Ralph Progress

Quick status check for the current Ralph run without executing any stories.

## Usage

```bash
/ralph-status              # Show current PRD status
/ralph-status --verbose    # Include recent progress entries
```

## What It Shows

```
╔═══════════════════════════════════════════════════════════════╗
║  🎭 RALPH WIGGUM STATUS                                       ║
╚═══════════════════════════════════════════════════════════════╝

Project: TaskApp
Branch: ralph/task-priority
Progress: 2/4 stories complete (50%)

┌─────────────────────────────────────────────────────────────────┐
│  STORIES                                                        │
├─────────────────────────────────────────────────────────────────┤
│  [✓] US-001: Add priority field to database                    │
│  [✓] US-002: Display priority indicator on task cards          │
│  [ ] US-003: Add priority selector to task edit      ← NEXT    │
│  [ ] US-004: Filter tasks by priority                          │
└─────────────────────────────────────────────────────────────────┘

Source: Linear issue ENG-1234
Started: 2024-01-15 10:30 AM
Last Activity: 2024-01-15 11:45 AM

Run `/ralph` to continue execution.
```

## Implementation

When `/ralph-status` is invoked:

```javascript
// 1. Check if ralph/prd.json exists
const prdPath = "ralph/prd.json";
if (!fileExists(prdPath)) {
  console.log("No active Ralph run. Create a PRD first with /prd");
  return;
}

// 2. Read the PRD
const prd = JSON.parse(readFile(prdPath));

// 3. Calculate progress
const total = prd.userStories.length;
const completed = prd.userStories.filter(s => s.passes).length;
const percentage = Math.round((completed / total) * 100);

// 4. Find next story
const nextStory = prd.userStories.find(s => !s.passes);

// 5. Read progress.txt for recent activity
const progressPath = "ralph/progress.txt";
const progress = fileExists(progressPath) ? readFile(progressPath) : null;

// 6. Display status
displayStatus({
  project: prd.project,
  branch: prd.branchName,
  stories: prd.userStories,
  completed,
  total,
  percentage,
  nextStory,
  recentProgress: progress
});
```

## Verbose Mode

With `--verbose`, also shows:

- **Codebase Patterns** section from progress.txt
- Last 3 completed story summaries
- Any notes or blockers recorded

```
Recent Progress:
────────────────
## 2024-01-15 11:45 - US-002
- Added priority badge component
- Integrated with task card
- Learnings: Use existing Badge component with color prop

## 2024-01-15 10:45 - US-001
- Added priority column to tasks table
- Migration ran successfully
- Learnings: Use enum type for priority values

Codebase Patterns Discovered:
─────────────────────────────
- Use existing Badge component for status indicators
- Migrations should use IF NOT EXISTS
- Priority enum: 'high' | 'medium' | 'low'
```

## No Active Run

If no `ralph/prd.json` exists:

```
╔═══════════════════════════════════════════════════════════════╗
║  🎭 RALPH WIGGUM STATUS                                       ║
╚═══════════════════════════════════════════════════════════════╝

No active Ralph run found.

To start:
1. Create a PRD:  /prd ENG-1234
2. Convert it:    Load ralph-converter skill
3. Run Ralph:     /ralph

Or check archived runs in ralph/archive/
```

## Archived Runs

If there are archived runs, list them:

```
Previous Runs (ralph/archive/):
───────────────────────────────
- 2024-01-10-user-auth (4/4 complete)
- 2024-01-05-dashboard-filters (6/6 complete)
- 2024-01-02-notification-system (8/8 complete)
```

## Related

- `/ralph` - Run the autonomous agent loop
- `/prd` - Create a new PRD

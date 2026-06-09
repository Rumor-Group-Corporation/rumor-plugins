#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop for Claude Code
# Usage: ./ralph.sh [max_iterations]
#
# "Me fail English? That's unpossible!" - Ralph Wiggum

set -e

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Ralph working directory
RALPH_DIR="$REPO_ROOT/ralph"
PRD_FILE="$RALPH_DIR/prd.json"
PROGRESS_FILE="$RALPH_DIR/progress.txt"
ARCHIVE_DIR="$RALPH_DIR/archive"
LAST_BRANCH_FILE="$RALPH_DIR/.last-branch"
PROMPT_FILE="$PLUGIN_DIR/templates/prompt.md"

# Ensure ralph directory exists
mkdir -p "$RALPH_DIR"
mkdir -p "$ARCHIVE_DIR"

# Check for required files
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: No prd.json found at $PRD_FILE"
  echo ""
  echo "Create a PRD first:"
  echo "  1. Run /prd to generate a PRD"
  echo "  2. Load the ralph-converter skill to convert it to prd.json"
  echo ""
  exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed."
  echo "Install with: brew install jq"
  exit 1
fi

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Display header
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   🎭 RALPH WIGGUM - Autonomous Agent Loop                    ║"
echo "║                                                               ║"
echo "║   \"Me fail English? That's unpossible!\"                      ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Starting Ralph - Max iterations: $MAX_ITERATIONS"
echo "PRD: $PRD_FILE"
echo "Progress: $PROGRESS_FILE"
echo ""

# Show current PRD status
echo "Current PRD Status:"
jq -r '.userStories[] | "  [\(if .passes then "✓" else " " end)] \(.id): \(.title)"' "$PRD_FILE"
echo ""

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  # Check if all stories are complete before starting
  INCOMPLETE=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE")
  if [ "$INCOMPLETE" -eq 0 ]; then
    echo ""
    echo "🎉 All stories already complete!"
    echo ""
    exit 0
  fi

  # Run Claude Code with the ralph prompt
  # Using --dangerously-skip-permissions for autonomous operation
  OUTPUT=$(cat "$PROMPT_FILE" | claude --dangerously-skip-permissions 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  🎉 Ralph completed all tasks!"
    echo "  Completed at iteration $i of $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    # Show final status
    echo "Final PRD Status:"
    jq -r '.userStories[] | "  [✓] \(.id): \(.title)"' "$PRD_FILE"
    echo ""

    exit 0
  fi

  echo ""
  echo "Iteration $i complete. Continuing to next iteration..."
  sleep 2
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ⚠️  Ralph reached max iterations ($MAX_ITERATIONS)"
echo "  without completing all tasks."
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Check progress:"
echo "  cat $PROGRESS_FILE"
echo ""
echo "Remaining stories:"
jq -r '.userStories[] | select(.passes == false) | "  [ ] \(.id): \(.title)"' "$PRD_FILE"
echo ""
exit 1

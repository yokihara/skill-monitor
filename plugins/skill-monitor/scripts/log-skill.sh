#!/bin/bash
# skill-monitor: log every Claude Code skill invocation as one JSONL record.
#
# Handles the two distinct invocation paths (see README):
#   - PreToolUse(Skill)   : Claude invokes a skill through the Skill tool
#   - UserPromptExpansion : the user types a /slash-command directly
#
# Always exits 0 (non-blocking) and never writes to stdout, so it can never
# interfere with the prompt expansion or the tool call.
set -uo pipefail

INPUT=$(cat)
EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)

SKILL=""
ARGS=""
SOURCE=""

case "$EVENT" in
  PreToolUse)
    TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
    [ "$TOOL" != "Skill" ] && exit 0
    SKILL=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
    ARGS=$(printf '%s' "$INPUT" | jq -r '.tool_input.args // .tool_input.arguments // ""' 2>/dev/null)
    SOURCE="tool"
    ;;
  UserPromptExpansion)
    # Prefer the structured command field; fall back to parsing the first
    # /token of the prompt in case a future version omits it.
    SKILL=$(printf '%s' "$INPUT" | jq -r '.command // empty' 2>/dev/null)
    if [ -z "$SKILL" ]; then
      PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null)
      FIRST=$(printf '%s\n' "$PROMPT" | head -n1)
      # Pure parameter expansion (avoids the bash 3.2 + UTF-8 locale =~ bug).
      case "$FIRST" in
        /*)
          rest="${FIRST#/}"
          SKILL="${rest%%[[:space:]]*}"
          ARGS="${rest#"$SKILL"}"
          ARGS="${ARGS#"${ARGS%%[![:space:]]*}"}"
          ;;
      esac
    fi
    SOURCE="typed"
    ;;
  *)
    exit 0
    ;;
esac

[ -z "$SKILL" ] && exit 0

# Data dir: the plugin data area when available, else a stable home fallback.
LOG_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/skill-monitor}"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/skill-usage.jsonl"

# Pointer file so the skill-stats CLI can locate the log without env vars.
PTR_DIR="$HOME/.claude/skill-monitor"
mkdir -p "$PTR_DIR" 2>/dev/null
printf '%s\n' "$LOG_FILE" > "$PTR_DIR/.logpath" 2>/dev/null

SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"
PROJECT=$(basename "$CWD")
TS=$(date +"%Y-%m-%dT%H:%M:%S%z")
EPOCH=$(date +%s)

jq -nc \
  --arg ts "$TS" --argjson epoch "$EPOCH" \
  --arg skill "$SKILL" --arg args "$ARGS" --arg source "$SOURCE" \
  --arg session "$SESSION" --arg cwd "$CWD" --arg project "$PROJECT" \
  '{ts:$ts,epoch:$epoch,skill:$skill,args:$args,source:$source,session:$session,cwd:$cwd,project:$project}' \
  >> "$LOG_FILE" 2>/dev/null

exit 0

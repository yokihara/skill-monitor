---
description: Show your Claude Code skill usage stats from skill-monitor. Trigger when the user runs /skill-monitor:skill-stats.
disable-model-invocation: true
allowed-tools: Bash
argument-hint: "[recent N | today | project | source]"
---

# Skill usage stats

Below is the live output of the `skill-stats` CLI (from the skill-monitor plugin):

!`skill-stats $ARGUMENTS 2>/dev/null || "$CLAUDE_SKILL_DIR/../../bin/skill-stats" $ARGUMENTS 2>/dev/null || echo "skill-stats CLI not found (checked PATH and the plugin bin/ directory)."`

Present the table above to the user as-is, with no extra commentary. If it shows "No usage log yet", tell them records start accumulating once a skill is used in a session with the plugin installed (a fresh session, since hooks load at session start).

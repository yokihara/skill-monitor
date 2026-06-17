# skill-monitor

> Track which Claude Code skills (slash commands) you actually use — how often, with what, and in which project.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757)

Claude Code can accumulate dozens — even hundreds — of skills, but there's no built-in way to answer *"which of these do I actually use?"* (see [anthropics/claude-code#35319](https://github.com/anthropics/claude-code/issues/35319)). `skill-monitor` fills that gap with two lightweight hooks and a small query CLI.

**100% local.** Nothing is ever sent anywhere.

## Example

```text
$ skill-stats
Total: 128 calls  |  log: ~/.claude/skill-monitor/skill-usage.jsonl

COUNT  SKILL          LAST_USED
42     commit         2026-06-16T17:26:03+0900
31     pull-request   2026-06-16T16:10:55+0900
18     worktree-list  2026-06-15T09:41:12+0900
12     new-feature    2026-06-14T11:02:48+0900

$ skill-stats recent 4
TIME                      SKILL          SRC    ARGS         PROJECT
2026-06-16T17:26:03+0900  commit         typed  fix login    my-app
2026-06-16T17:10:22+0900  worktree-list  tool   -            my-app
2026-06-16T16:10:55+0900  pull-request   typed  -            my-app
2026-06-15T09:41:12+0900  new-feature    typed  DEVWEB-1234  api

$ skill-stats source
By source (tool vs typed):

COUNT  SOURCE
80     typed
48     tool
```

## Features

- 🪶 **Two hooks, full coverage** — captures both skills Claude invokes (the `Skill` tool) and slash commands you type yourself.
- 📊 **Instant stats** — per-skill totals, recents, today, per-project, and a tool-vs-typed breakdown.
- 🔒 **Local only** — one JSONL file on your disk; no network, no telemetry.
- 🧩 **Zero config** — install the plugin and the hooks activate automatically; no `settings.json` edits.
- 🪝 **Non-blocking** — hooks always exit `0` and never touch stdout, so they can't interfere with anything.

## Requirements

- [Claude Code](https://claude.com/claude-code) with plugin support
- [`jq`](https://jqlang.github.io/jq/)

## Install

```
/plugin marketplace add yokihara/skill-monitor
/plugin install skill-monitor@skill-monitor
```

Start a new session — the hooks are active automatically.

### Local test before publishing

```
/plugin marketplace add /absolute/path/to/skill-monitor
/plugin install skill-monitor@skill-monitor
claude plugin validate /absolute/path/to/skill-monitor
```

## Usage

### Inside Claude Code (slash command)

After installing, type the slash command right in Claude Code:

```
/skill-monitor:skill-stats            # per-skill totals
/skill-monitor:skill-stats recent 20  # last 20 invocations
/skill-monitor:skill-stats today      # today's usage
/skill-monitor:skill-stats source     # tool vs typed
```

### From your terminal (CLI)

The CLI also ships at `bin/skill-stats` inside the plugin. Locate it and alias it in your shell rc:

```
find ~/.claude/plugins -name skill-stats -path '*skill-monitor*'   # locate it
alias skill-stats="/path/from/above"
```

```
skill-stats            # per-skill totals + last used (default)
skill-stats recent 20  # last 20 invocations (with source)
skill-stats today      # today's usage
skill-stats project    # per-project totals (or: project <name>)
skill-stats source     # tool vs typed breakdown
skill-stats raw        # print the resolved log path
```

## How it works

Every invocation is appended as one JSON line. Two paths are covered, and they don't overlap (so there's no double counting):

| You do this | Hook that fires | Skill name from | `source` |
|-------------|-----------------|-----------------|----------|
| Claude invokes a skill via the `Skill` tool | `PreToolUse` (matcher `Skill`) | `tool_input.skill` | `tool` |
| You type a `/command` yourself | `UserPromptExpansion` | the `command` field | `typed` |

A record looks like:

```json
{"ts":"2026-06-16T17:26:03+0900","epoch":1781598363,"skill":"commit","args":"fix login","source":"typed","session":"…","cwd":"…","project":"my-app"}
```

## Data & privacy

- Log file: `${CLAUDE_PLUGIN_DATA}/skill-usage.jsonl`, falling back to `~/.claude/skill-monitor/skill-usage.jsonl`.
- A pointer file at `~/.claude/skill-monitor/.logpath` lets the CLI find the log without environment variables.
- **Local only — no network calls.** Records contain the skill name, args, timestamp, session id, and cwd/project. Delete the file any time to reset.

## Uninstall

```
/plugin uninstall skill-monitor@skill-monitor
/plugin marketplace remove skill-monitor
```

Then optionally remove leftover data:

```
rm -rf ~/.claude/skill-monitor
```

## Caveats

- The `UserPromptExpansion` event and its `command` field follow the Claude Code hooks documentation. If a future version changes them, the typed path falls back to parsing the first `/token` of the prompt.
- Args for typed commands are best-effort: the structured payload exposes the command name reliably, while arguments are parsed from the prompt.

## Contributing

Issues and PRs welcome. Please keep the hooks non-blocking (always `exit 0`, no stdout) and the CLI dependency-light (POSIX shell + `jq`).

## License

[MIT](./LICENSE)

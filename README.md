# AI Harness Engineering Scaffold

```
.
├── codebases/     # code projects (1+) to install, debug, develop, or study; contents gitignored — clone in or add as submodule
│   └── REPOS.md   # tracked list of repos + pinned commits
├── experiments/   # <codename>/INTENT.md (plan) + <codename>/<YYYY-MM-DD_HHMM>/ per run — self-contained setup + logs; code name: short, unique kebab-case
├── reports/       # YYYY-MM-DD_<codename>_<agent>_worklog.md (raw trace, one per agent) + YYYY-MM-DD_<codename>_summary.md (distilled; blockers + decisions on top)
├── memory/        # <topic>.md, one topic each, with frontmatter (name, description, type); evidence on each fact; the directory is the index
├── files/         # user-provided attachments
├── CLAUDE.md      # canonical instructions for all agent tools
├── AGENTS.md      # symlink to CLAUDE.md, for Codex and Cursor
├── .agents/       # tool-neutral agent files
│   └── skills/    # symlink to .claude/skills, for Codex and Cursor
├── .claude/       # Claude Code settings: auto memory off (settings.local.json gitignored)
│   └── skills/    # project skills, auto-triggered; third-party sources in skills/THIRD_PARTY.md
├── .codex/        # Codex project config: memories off (loaded when the project is trusted)
└── .gitignore
```

## Project Scope

_TODO: describe the goal, success criteria, verifier, scope boundary, and any constraints specific to this project._

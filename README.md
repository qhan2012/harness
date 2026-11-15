# AI Harness Engineering Scaffold

```
.
├── codebases/     # code projects (1+) to install, debug, develop, or study; contents gitignored — clone in or add as submodule
│   └── REPOS.md   # tracked list of repos + pinned commits
├── experiments/   # <codename>/<YYYY-MM-DD_HHMM>/ per run — self-contained setup + logs; code name: short, unique kebab-case
├── reports/       # YYYY-MM-DD_worklog.md (raw trace) + _summary.md (distilled; blockers + decisions on top)
├── memory/        # <name>.md with frontmatter (name, description, type); evidence on each fact; one line per entry in MEMORY.md
├── files/         # user-provided attachments
├── MEMORY.md      # memory index, read at session start (header only in the scaffold)
├── AGENTS.md      # canonical instructions for all agent tools; Codex and Cursor read it directly
├── CLAUDE.md      # Claude Code entry point: imports AGENTS.md and MEMORY.md
├── .agents/       # tool-neutral agent files
│   └── skills/    # symlink to .claude/skills, for Codex and Cursor
├── .claude/       # Claude Code settings + skills (auto memory off; settings.local.json gitignored)
│   └── skills/    # project skills, auto-triggered; third-party sources in skills/THIRD_PARTY.md
└── .gitignore
```

## Start a project

This repo is the scaffold only. Each project lives in its own repo, outside this account. In the project repo, `origin` is the project and `upstream` is this scaffold, pull only.

```bash
git clone https://github.com/qhan2012/harness <project>
cd <project>
git remote rename origin upstream
git remote set-url --push upstream DISABLED   # never push project work to the scaffold
git remote add origin <project-repo-url>
git push -u origin main
```

Then fill in § Project Scope. To get scaffold updates later, run `git fetch upstream && git merge upstream/main`. Do not create the project from a GitHub template: a template drops the shared history, so later merges fail.

## Project Scope

_TODO: describe the goal, success criteria, verifier, scope boundary, and any constraints specific to this project._

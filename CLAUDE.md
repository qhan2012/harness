# Claude Code Instructions

Scope: `harness/` only. Read `README.md § Project Scope` first — do not violate without permission.
Source code and GitHub are ground truth — when asked critical questions or in conflict with memory or summaries, always read the repo first.
Log key findings to `MEMORY.md`.

## Rules (non-negotiable)

1. **Think like an architect.** Customer-ready deliverables. Anticipate hard questions before they're asked.
2. **Apple-to-apple comparisons.** Same data, hardware, config — only the variable under test changes.
3. **Reports: precise, short, self-contained.** Cover model, date, prompt, metric, result. A reader should understand the finding without chasing other files.
4. **Separate correctness and perf runs.** Remind if correctness is unchecked at milestones or final.
5. **Every run is self-contained.** No hardcoded params or seeds — must be reproducible in isolation.

Ask before: changing scope, loosening tolerances, adding root files or deps, touching parent code.

## Autonomous long-run mode (>30 min, no human)

Run until the goal is achieved. Never pause for human input — log blockers to `reports/YYYY-MM-DD_blockers.md` and skip. Write `reports/YYYY-MM-DD_summary.md` at job end.

1. **Write intent before launch.** Describe goal and constraints in a guidance file.
2. **One change per iteration.** Edit only one file or component — keeps diffs reviewable, prevents cascading failures.

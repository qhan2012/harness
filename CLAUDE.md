# Claude Code Instructions

Scope: `harness/` only. Read `README.md § Project Scope` first — do not violate without permission.
Source code and GitHub are ground truth — when asked critical questions or in conflict with memory or summaries, always read the repo first.
Memory: add when you learn, update when refined, remove when wrong — keep `MEMORY.md` current.

## Rules (non-negotiable)

1. **Think like an architect.** Deep dive to ground truth. Deliver customer-ready work. Anticipate hard questions before they're asked.
2. **Verify before high-impact changes.** Check ownership of shared resources (processes, files, SLURM jobs). Ask before changing scope, loosening tolerances, adding root files or deps, or touching parent code.
3. **Smoke test where needed.** Before long runs or major changes, verify the basic setup works end-to-end.
4. **Apple-to-apple comparisons.** Same data, hardware, config — only the variable under test changes.
5. **Reports: precise, short, easy to understand.** Cover model, date, prompt, metric, result. A reader should understand the finding without chasing other files.
6. **Separate correctness and perf runs.** Remind if correctness is unchecked at milestones or final.
7. **Every run is self-contained.** No hardcoded params or seeds — must be reproducible in isolation.

## Autonomous long-run mode (>30 min, no human)

Run until the goal is achieved. Never pause for human input — log blockers to `reports/YYYY-MM-DD_blockers.md` and skip. Write `reports/YYYY-MM-DD_summary.md` at job end.

1. **Write intent before launch.** Describe goal and constraints in a guidance file.
2. **One change per iteration.** Edit only one file or component — keeps diffs reviewable, prevents cascading failures.
3. **Validate each step before moving on.** Confirm the current iteration succeeded — don't compound errors across steps.

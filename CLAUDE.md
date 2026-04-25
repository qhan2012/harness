# Claude Code Instructions

Scope: `harness/` only. Read `README.md § Project Scope` first — do not violate without permission.
Source code and GitHub are ground truth — when asked critical questions or in conflict with memory or summaries, always read the repo first.
Log key findings to `MEMORY.md`. Keep reports factual: model, date, prompt, metric, result.

## Rules (non-negotiable)

1. **Think like an architect.** Customer-ready deliverables. Anticipate hard questions before they're asked.
2. **Separate correctness and perf runs.** Remind if correctness is unchecked at milestones or final.
3. **Apple-to-apple comparisons.** Same data, hardware, config — only the variable under test changes.
4. **Every run is self-contained.** Must be reproducible in isolation.
5. **No hardcoded params, including seeds.** Everything variable goes in a config file.
6. **Perf trials by weight.** Lightweight: ≥5 trials; multinode: 1 trial.

Ask before: changing scope, loosening tolerances, adding root files or deps, touching parent code.

## Autonomous long-run mode (>30 min, no human)

Run until the goal is achieved. Never pause for human input — log blockers to `reports/YYYY-MM-DD_blockers.md` and skip. Write `reports/YYYY-MM-DD_summary.md` at job end.

1. **Write intent before launch.** Describe goal and constraints in a guidance file — the only mid-run communication channel.
2. **One change per iteration.** Edit only one file or component — keeps diffs reviewable, prevents cascading failures.
3. **One metric decides.** Retain if it improves; discard otherwise. No human judgment mid-run.

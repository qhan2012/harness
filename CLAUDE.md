# Claude Code Instructions

Scope: `harness/` only. Read `README.md § Scope` first — do not violate without permission.
Source code and GitHub are ground truth — when asked critical questions or in conflict with memory or summaries, always read the repo first.
Log key findings to `MEMORY.md`. Keep reports factual: model, date, prompt, metric, result.

## Rules (non-negotiable)

1. Correctness and perf are separate runs. Remind if correctness has not been checked at each milestone or final.
2. No hardcoded params — including seeds. Everything configurable goes in a config file.
3. Every run dir must be self-contained and reproducible.
4. **Perf trials depend on test weight.** Lightweight: ≥5 trials; multinode: 1 trial is ok.

Ask before: changing scope, loosening tolerances, adding root files or deps, touching parent code.

## Autonomous long-run mode (>30 min, no human)

Run until the goal is achieved. Never pause for human input — log blockers to `reports/YYYY-MM-DD_blockers.md` and skip. Write `reports/YYYY-MM-DD_summary.md` at job end.

1. **Fixed time budget per run.** Every run gets the same wall-clock limit — results stay comparable across all variations.
2. **Single modification point.** The agent edits only one file or component per iteration — keeps diffs reviewable and prevents cascading failures.
3. **Retain or discard on one metric.** One unambiguous signal decides keep or discard. No human judgment mid-run.
4. **Intent lives in a guidance file.** Written before launch, read at every iteration. The only way to steer the agent mid-run.

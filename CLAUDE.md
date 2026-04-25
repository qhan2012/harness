# Claude Code Instructions

Scope: `harness/` only. Read `README.md § Scope` first — do not violate without permission.
Log key findings to `MEMORY.md`. Keep reports factual: model, date, prompt, metric, result.

## Rules (non-negotiable)

1. Correctness and perf are separate runs. Correctness gate must be green before perf begins.
2. No hardcoded params — including seeds. Everything configurable goes in a config file.
3. Every run dir must be self-contained and reproducible.
4. Reference is untouchable and obviously correct. Never modify it or share code with the SUT.
5. Perf: ≥10 trials + warmup ≥3. Report P50/P99. Always state the run dir.
6. Run dir format: `<ts>[_<tag>]/`.

Ask before: changing scope, loosening tolerances, adding root files or deps, touching parent code.

## Autonomous long-run mode (>30 min, no human)

Run until the goal is achieved. Never pause for human input — log blockers to `reports/YYYY-MM-DD_blockers.md` and skip. Correctness gate is self-evaluated against defined thresholds; on failure skip perf and continue. Write `reports/YYYY-MM-DD_summary.md` at job end. Fixed time budget per run — never expand. Retain only if primary metric improves; one metric only. Intent must be written in the experiment dir before launch — only communication channel mid-run.

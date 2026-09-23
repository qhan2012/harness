# Claude Code Instructions

Scope: this workspace only. Read `README.md § Project Scope` first — do not violate without permission.
The references (code, official docs, GitHub) and the evidence (run logs, outputs, metrics) are ground truth; memory and summaries are not — they can be stale.
When they conflict, or a question is critical, go back to ground truth before answering.
Memory: add when you learn, update when refined, remove when wrong — keep `MEMORY.md` (project root) current.

## Rules (non-negotiable)

1. **Think like an architect.** Deep dive to ground truth. Deliver customer-ready work. Anticipate hard questions before they're asked.
2. **Verify before high-impact changes.** Check ownership of shared resources (processes, files, GPUs, scheduler/cluster jobs, ports). Ask before loosening tolerances or touching root files/deps.
3. **Smoke test where needed.** Before long runs or major changes, verify the basic setup works end-to-end.
4. **Apple-to-apple comparisons.** Same data, hardware, config — only the variable under test changes.
5. **Reports: precise, short, easy to understand.** Cover model, date, prompt, metric, result.
6. **Separate correctness and perf runs.** Remind if correctness is unchecked at milestones or final.
7. **Every run is self-contained.** No hardcoded params or seeds — must be reproducible in isolation.
8. **Reply in English or Chinese only.** Match the prompt; default to English.
9. **Write plainly.** Precise, short, easy-to-understand sentences — in replies, docs, and reports alike.

## Autonomous long-run mode (>30 min, no human)

Run until the goal is achieved. Never pause for human input. Keep a running trace in `reports/YYYY-MM-DD_worklog.md` (append one entry per iteration); at job end write `reports/YYYY-MM-DD_summary.md` with any blockers lifted into a section at the top. Pipeline: worklog (raw) → summary (distilled for humans) → memory (only durable lessons graduate — from successes, failures, or strong evidence-backed findings).

1. **Research prerequisites first.** Establish ground truth before writing intent — read the repo, and where relevant consult authoritative external docs (cite sources in the worklog); source code/GitHub wins on any conflict.
2. **Write intent before launch.** Describe goal and constraints in a guidance file.
3. **One change per iteration.** Edit only one file or component — keeps diffs reviewable, prevents cascading failures.
4. **Validate each step before moving on.** Confirm the current iteration succeeded — don't compound errors across steps.

**On a blocker at any step, escalate before skipping:** do more research → step back for a detour → weigh alternative approaches. Only flag it in the worklog (prefix `BLOCKER:`) and skip once the options are genuinely exhausted.

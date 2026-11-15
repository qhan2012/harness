# Agent Instructions

Scope: this workspace only. Read `README.md § Project Scope` first — do not violate without permission.
The references (code, official docs, GitHub) and the evidence (run logs, outputs, metrics) are ground truth; memory and summaries are not — they can be stale.
When they conflict, or a question is critical, go back to ground truth before answering.

## Memory

The repo is the only memory, so any agent tool can continue the work. Write durable knowledge to `memory/<name>.md`, then run `python3 scripts/memory_index.py` to rebuild `MEMORY.md`. Do not edit `MEMORY.md` by hand. Do not rely on a tool's built-in memory (Claude Code auto memory, Codex memories, Cursor Memories). This repo turns them off where it can: `.claude/settings.json` and `.codex/config.toml`. If a tool's built-in memory or user-level instructions conflict with the repo, the repo wins; copy any durable fact found only in a tool's memory into `memory/`.

- Add when you learn, update when refined, remove when wrong.
- Frontmatter: `name`, `description`, and `type`, one of `reference` (facts about code or tools), `lesson` (what worked or failed in runs), `project` (state and decisions), `feedback` (the user's preferences and corrections).
- End each fact with its evidence: `(verified YYYY-MM-DD, <source: command, log, or run code name>)`. Check an old fact again before you rely on it for a critical decision. A fact about a repo in `codebases/` is stale when that repo's commit in `codebases/REPOS.md` changes.
- Never write secrets, tokens, or passwords to memory.
- When the same lesson comes back, encode it as a rule, skill, or check instead of more memory.

## Session handoff

Work must survive a switch between Claude Code, Codex, and Cursor, and a session that ends without warning.

- Start: read `MEMORY.md`, the plan in `experiments/<codename>/INTENT.md`, and the latest worklog and summary in `reports/`.
- Each iteration: commit and push the worklog. Do not wait for the end.
- Before you stop or switch tools: record running jobs (process IDs, scheduler job IDs, GPUs) and uncommitted work in the worklog. Then commit and push the worklog, memory, `MEMORY.md`, and `codebases/REPOS.md`.
- A Stop hook (`scripts/handoff_check.sh`) blocks the end of a turn while those files are uncommitted or unpushed, or `MEMORY.md` is out of date. It runs in Claude Code and Codex; Cursor does not run it.
- Never push project content to the scaffold repo (`qhan2012/harness`).

## Rules (non-negotiable)

1. **Think like an architect.** Deep dive to ground truth. Deliver customer-ready work. Anticipate hard questions before they're asked.
2. **Verify before high-impact changes.** Check ownership of shared resources (processes, files, GPUs, scheduler/cluster jobs, ports). Ask before loosening tolerances or touching root files/deps.
3. **Smoke test where needed.** Before long runs or major changes, verify the basic setup works end-to-end.
4. **Apple-to-apple comparisons.** Same data, hardware, config — only the variable under test changes.
5. **Reports: precise, short, easy to understand.** Cover code name, model, date, prompt, metric, result.
6. **Separate correctness and perf runs.** Remind if correctness is unchecked at milestones or final.
7. **Every run is self-contained.** No hardcoded params or seeds — must be reproducible in isolation.
8. **Reply in English or Chinese only.** Match the prompt; default to English.
9. **Write plainly.** Use ASD-STE100-style simplified technical language — short, active-voice sentences and consistent terms — while preserving technical accuracy.

## Autonomous long-run mode (>30 min, unattended)

Run until the goal is achieved. Never block on human input. Keep a running trace in `reports/YYYY-MM-DD_worklog.md` (append-only; one entry per iteration: what, why, evidence, result); at job end write `reports/YYYY-MM-DD_summary.md` with any blockers and decisions lifted into a section at the top. Pipeline: worklog (raw) → summary (distilled for humans) → memory (only durable lessons graduate — from successes, failures, or strong evidence-backed findings).

1. **Research prerequisites first.** Establish ground truth before writing intent — read the repo, and where relevant consult authoritative external docs (cite sources in the worklog); source code/GitHub wins on any conflict.
2. **Write intent before launch.** Describe goal and constraints in `experiments/<codename>/INTENT.md`.
3. **One change per iteration.** Edit only one file or component — keeps diffs reviewable, prevents cascading failures.
4. **Validate each step before moving on.** Confirm the current iteration succeeded — don't compound errors across steps.

**On a blocker at any step, escalate before skipping:** do more research → step back for a global view → find the best direction. Only flag it in the worklog (prefix `BLOCKER:`) and skip once no viable direction remains.

**On an unanswered question, decide after 30 min:** when you ask, state a recommended default. If no answer comes within 30 min, apply it, log it in the worklog (prefix `DECISION:`), and report it at the next progress check. The 30-min limit needs a tool that can wake itself on a timer; without one, decide at the start of the next turn. This applies only to reversible choices. For an irreversible action (force-push, deleting data, sending external messages), wait for an answer: log it as `BLOCKER:` and continue with other work.

---
name: hyperloom
description: AMD-AGI Hyperloom — multi-agent harness for LLM inference optimization on AMD GPUs; loop, roles, gates, KB
type: reference
---
Source: AMD-AGI/Hyperloom @ a60d579 (2026-10-06), v1.1.3, ~318k Python lines. Local clone: `codebases/Hyperloom`. Ground truth docs: `docs/conceptual/optimization-loop.md`, `AGENTS.md`, `src/hyperloom/inference_optimizer/SKILL.md`.

- Goal: optimize end-to-end serving throughput (vLLM, SGLang, xDiT) on MI300X/MI325X/MI355X with no per-model human tuning. CLI: `python -m hyperloom.inference_optimizer.cli optimize`.
- Phase chain: PRELUDE (baseline + roofline/profile, optional recipe replay) -> ENABLEMENT (only if baseline fails; ladder Rung 0-5: diagnose, flags, source patch, attempt venv, PR localization, off-loop compiled build) -> FRAMEWORK_AGENT (explore server-arg/env grids + integrate_patch from specialist or upstream PR) -> KERNEL_AGENT (GEAK default, or Forge: GEMM tune -> fusion -> kernel rewrite) -> SWEEP (concurrency ladder) -> CLOSE (report, session_breakdown.json). Macro-cycle reloop to FRAMEWORK while budget + roofline headroom remain.
- Roles: Orchestration (stateless planner, re-seeded each tick from state, not transcript), Critic (rules every keep/revert), Specialist (ephemeral, returns a diff only).
- Key trust rules: coordinator runs all benchmarks; agent-predicted gains never decide KEEP; backend-claimed speedups are unverified until re-measured; failed changes revert; KEEP becomes new baseline; full-stack revalidation after each KEEP. PolicyGate enforces path sandbox, leases, single-writer; phase transitions are GPU barriers.
- Recipe KB: read at start, written at close; lookup relaxes one field at a time (model, hw, framework, model type, arch, version, precision). Strict admission.
- GEMM tuning link: `src/kernelforge/gemm_tune` (deterministic, no LLM): aiter CK tuners for SGLang, PyTorch TunableOp (hipBLASLt/rocBLAS) for vLLM dense. Does NOT call GEKO as of a60d579 (grep found no "geko").
- gemm_tune tuner contract (`src/kernelforge/gemm_tune/tuners/base.py`): subclass BaseTuner (validate/run -> TuneResult with env_var/env_value, shape_results, candidate). Register in `utils.TUNER_ENV_VARS` + `router.py` selection. CLI prints result.json between FORGE_GEMM_TUNE_RESULT_BEGIN/END; Hyperloom applies `recommended_env`, restarts server, decides KEEP/REVERT by E2E.

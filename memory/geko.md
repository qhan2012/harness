---
name: geko
description: GEKO (hipBLASLt GEMM Kernel Optimizer) — architecture, workflows, key thresholds
type: reference
---
Source: ROCm/rocm-libraries `projects/hipblaslt/utilities/geko` @ 7943b63 (2026-10-06). Local sparse clone: `codebases/rocm-libraries`.

- Purpose: offline GEMM tuning for hipBLASLt (AMD GPUs). Input = workload GEMM list; output = Tensile logic YAMLs (`final_libs/`) merged into hipBLASLt with `TensileMergeLibrary`, then rebuild.
- Entry: `bin/geko --tune | --search | --bench`; workload from `--workload-log` (HIPBLASLT_LOG_MASK=64 YAML), `--list` (generator YAML), or `--inline M N B K dt dst ct tA tB [MX]`.
- `--tune` (hours): `pipeline.run_configure` -> `config_generator` writes tensilelite configs (MI design + per-arch fork params in `config_generator/fork_params/hw_profiles/{gfx942,gfx950,gfx1250}`) -> `optim.run` runs `tensilelite/Tensile/bin/Tensile` per config. Backend `ductile` (genetic algorithm, default, search_space=generic) or `tensile` (exhaustive grid, search_space=heuristic).
- `--search` (minutes): dense benchmark of existing solutions with hipblaslt-bench `algo_method=1, requested_solution_num=-1`; winner = min `us` per GEMM; extract via `MatchTable.yaml`. Chunks of <=25 GEMMs per device, failed chunks retried one GEMM each; resume via `processed.csv`.
- `optim.analyze` keep rule: kernel_tuned != kernel_reference AND ratio >= up_thr (default 1.03) AND error_tuned < err_thr (0.03). Writes raw_results.csv, final_results.csv, metrics.json (mean/geomean/weighted e2e uplift).
- `bench.standard_benchmark`: probe run (10 iters, 2 cold) then scale iters so each phase ~= duration (0.5 s).
- Concurrency: `concurrency/runner.py` Runner + Worker(setup/run/teardown), per-device slots, LPT ordering by estimated workload, GPU lock file per device.
- Resume/audit: `run_state.json` in workdir, verified against the input log.

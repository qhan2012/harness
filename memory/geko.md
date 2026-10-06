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
- Deploy without rebuild (verified in hipBLASLt develop source, `UserDrivenTuningParser.cpp` + `docs/how-to/how-to-use-hipblaslt-offline-tuning.rst`): `HIPBLASLT_TUNING_OVERRIDE_FILE` = CSV with header containing transA,transB,batch_count,m,n,k,a_type,b_type,c_type,compute_type,solution_index (+ kernel_name/solution_name). Rows are validated by name, so a version mismatch drops rows; it does not break the run. Override key has no epilogue/bias field. GEKO search output already has solution_index + solution_name (`bench/utils.py:157`).
- `HIPBLASLT_TENSILE_LIBPATH` replaces the whole library path. A lib built only from GEKO final_libs is NOT a full library; merge with base logic first.
- `HIPBLASLT_LOG_FILE` supports `%i` (pid), so TP ranks log to separate files.

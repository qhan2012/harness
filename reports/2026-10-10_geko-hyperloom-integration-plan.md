# GEKO → Hyperloom 集成：最佳实现方案与计划

日期：2026-10-10 · 分支：`claude/geko-hyperloom-notes`
源码版本：Hyperloom `a60d579`；rocm-libraries `origin/develop`（含 `ed988203a`、`faea76a5c`）。
范围：只覆盖走 hipBLASLt 的 GEMM。没有 GPU，本文所有结论来自源码和官方文档，未经实测。

## 1. 结论

推荐实现：**GEKO dense search → hipBLASLt 原生 tuning 文件 → Forge tuner → `HIPBLASLT_TUNING_OVERRIDE_FILE`**。

- override 文件由 `hipblaslt-bench` 自己写（设置 `HIPBLASLT_TUNING_FILE` 即可），GEKO 和 Hyperloom 都不手写 CSV。
- GEKO 上游增加一个 override 模式：搜索、按 override 文件做带精度检查的复测、按阈值过滤行。这个模式不再需要 `TensileCreateLibrary`。
- Hyperloom 只加一个 Forge tuner 和三处 coordinator 改动。KEEP/REVERT 仍由端到端测量决定。
- 运行时 hipBLASLt 必须包含 `ed988203a`（2026-10-01）。更早的版本 override 路径有已知缺陷（见 F1），只能在严格条件下使用。
- 生成新内核（Ductile + `HIPBLASLT_TENSILE_LIBPATH`）推迟。它会改变 solution index，和 aiter 的 hipBLASLt 行以及 override 文件冲突（见第 5 节）。

## 2. 改变设计的新事实

| # | 事实 | 来源 | 对设计的影响 |
|---|---|---|---|
| F1 | 2026-10-01 前的 override 路径有缺陷：`Git Version` 行不一致时整个文件被丢弃；同一 key 多行时，后面的行按第一行的 solution 检查；index 0 被拒绝；单算法请求时 `returnAlgoCount` 未初始化。修复后按 `kernel_name` 逐行校验。 | rocm-libraries `ed988203a`（#12585）提交说明 | 运行时版本是硬门槛。旧版本只能在"同一构建 + 每个 key 一行 + 不用 index 0"下使用。 |
| F2 | 设置 `HIPBLASLT_TUNING_FILE` 后，`hipblaslt-bench` 把每个问题的最优解追加写入该文件，带 `solution_index`、`kernel_name`、`gcnArchName`、`CUs`。 | `clients/common/include/argument_model.hpp`、`testing_matmul.hpp` | 不需要自写格式转换器。格式由 hipBLASLt 自己维护，随版本演进。 |
| F3 | override 只在 `hipblasLtMatmulAlgoGetHeuristic` 路径生效。每一行都对真实问题（含 bias、epilogue）跑 `isSolutionSupported`，不支持就试下一行，最后回退到默认启发式。 | `rocblaslt_auxiliary.cpp` `problem_override_from_file` | bias/epilogue 只影响性能，不影响正确性。传显式 algo 的调用方（TunableOp、aiter `hipb_mm`）会绕过 override。 |
| F4 | hipBLASLt 正在合入运行时 tuning cache（#10424 拆成 6 个 PR，已合 2 个）。新格式带 `schema_version`，key 覆盖完整问题（stride、epilogue、bias、设备等）。 | `faea76a5c`（#12586）提交说明 | 以后 hipBLASLt 可能自己做运行时调优，和 GEKO search 重叠。我们只依赖"tuning 文件"这个合约，以后能平滑换到新格式。 |
| F5 | Hyperloom 已有：vLLM 的 TunableOp 形状采集流程（单独启动一次服务器）、`recommended_env` 到 `extra_envs` 的转换、只认 aiter env 的持久化白名单、KERNEL 阶段的"候选不生效"检查（如 `aiter_moe_runtime_triton_config_inert`）。 | `orchestrator/kernel/request_handlers.py` `_capture_vllm_tunableop_shapes`、`_persist_forge_gemm_csv_durably`；`phases/kernel.py` | 采集、持久化、不生效检查都有现成位置可以扩展，不需要新机制。 |
| F6 | TunableOp 结果也是按 hipBLASLt solution index 选。开启 TunableOp 后，torch 直接传 algo，override 对这些 GEMM 不生效。 | F3 + `tuners/vllm_dense_tunableop.py` | 两个 tuner 对同一个 GEMM 互斥，不能同时 KEEP。 |

## 3. 方案比较

| 方案 | 做法 | 结论 |
|---|---|---|
| A | GEKO search（override 模式）→ 原生 tuning 文件 → Forge tuner → `HIPBLASLT_TUNING_OVERRIDE_FILE` | **采用。** 不用重编，回退只需去掉一个变量，格式由 hipBLASLt 维护，复用 Hyperloom 现有流程。 |
| B | 保持 GEKO 现有流程：抽取 solution → `TensileCreateLibrary` → `HIPBLASLT_TENSILE_LIBPATH` | 不采用。这样只能编出部分库，换成完整库又要几十分钟并改变 index（第 5 节）。 |
| C | 不用 GEKO，只靠现有 `vllm_dense_tunableop` | 作为 A/B 对照组。如果 A 不比它好，就不集成。 |
| D | 等 hipBLASLt 运行时 tuning cache 完成 | 继续跟踪。A 依赖的是 tuning 文件合约，到时可以切换。 |
| E | 把 GEKO 做成 LLM specialist 动作 | 不采用。调优是确定性工作，Forge tuner 本来就是为它设计的。 |

## 4. 选定实现（方案 A）

### 4.1 GEKO 上游（rocm-libraries，1 个 PR）

**G1：`--search --emit-override`**
1. `search.run` 的每个分块在调用 `hipblaslt-bench` 时，设置 `HIPBLASLT_TUNING_FILE=<workdir>/search/tuning_<chunk>.txt`。每个分块一个文件，多进程追加不会冲突。
2. 合并所有分块文件，保证每个问题 key 只保留一行（最快的那行）。
3. 新增 `optim.analyze_override`：对同一个 workload YAML 跑两遍 `hipblaslt-bench`，一遍默认，一遍设置 `HIPBLASLT_TUNING_OVERRIDE_FILE`，第二遍开验证。计算每个 GEMM 的 ratio 和 error。
4. 只保留同时满足三个条件的行：选中的 kernel 和默认不同、`ratio ≥ up_thr`、`error < err_thr`。输出 `final_override.txt` 和现有的 `metrics.json`。
5. 这条路径不调用 `TensileCreateLibrary`，也不产出 `final_libs/`。

合约测试：输出文件能被 hipBLASLt 解析器接受（表头至少含 `transA, solution_index`，第一行是 `Git Version:`）；每个 key 只有一行；没有改进时文件为空并给出明确的退出状态。

### 4.2 Hyperloom（4 个 PR，每个只做一件事）

**H1：形状采集时同时抓 hipBLASLt 日志**（`request_handlers.py` `_capture_vllm_tunableop_shapes`）
- 在已有的采集环境变量里加 `HIPBLASLT_LOG_MASK=64` 和 `HIPBLASLT_LOG_FILE=<capture_dir>/hipblaslt_%i.yaml`。服务器只启动一次，和 TunableOp 录制共用。
- 采集结束后把各 rank 的文件合并为一个 workload YAML，相同形状累加 `call_count`。
- 如果日志为空，说明这个服务没有调用 hipBLASLt。把这个结论写进结果，后面的 tuner 直接跳过。

**H2：Forge tuner `hipblaslt_geko_search`**
- 新文件 `src/kernelforge/gemm_tune/tuners/hipblaslt_geko_search.py`，继承 `BaseTuner`。
- `validate()` 拒绝运行的情况：
  - 找不到 GEKO 或 `hipblaslt-bench`；
  - 合并后的日志不存在或为空；
  - `hipblaslt-bench` 的构建版本和推理进程加载的 `libhipblaslt` 不一致；
  - 运行时版本早于 `ed988203a`，又不满足 F1 的严格条件。
- `run()`：调用 `geko --search --emit-override`，把 `final_override.txt` 填进 `TuneResult`：`env_var="HIPBLASLT_TUNING_OVERRIDE_FILE"`、`candidate=True`、`shape_results` 来自 GEKO 的 `final_results.csv`。
- 注册：`utils.TUNER_ENV_VARS` 加一项；`router._select_vllm_tuners` 在有 hipBLASLt 日志时选它，priority 20；`TuneContext` 和 CLI 加 `hipblaslt_log`、`hipblaslt_src`。

**H3：持久化与 recipe 复用**（`_persist_forge_gemm_csv_durably`）
- 现有白名单只认 aiter 的 env。override 文件不属于 aiter 包，应复制到 `<session>/optimization_stack/src/forge_gemm_<model>/` 并做快照，env 指向这个副本。
- `prelude._warm_kernel_extra_envs` 已经按文件名重新指向下载的副本，不用改。
- 顺带发现：`PYTORCH_TUNABLEOP_FILENAME` 和 `VLLM_TUNED_CONFIG_FOLDER` 现在也没有持久化。这是另一个问题，单独提 issue，不放进这个 PR。

**H4：不生效检查与 TunableOp 互斥**（`phases/kernel.py` 的候选循环）
- 当前栈里已开启 TunableOp（有 `PYTORCH_TUNABLEOP_*`）时，override 候选直接 REVERT，原因记为 `hipblaslt_override_inert`。按 F6，开了 TunableOp 后 override 不起作用。
- router 每次运行只选 `vllm_dense_tunableop` 和 `hipblaslt_geko_search` 其中之一，选哪个以 M0 的 A/B 结果为准。如果 A 全面胜出，就按 Hyperloom 的"Finish the replacement"规则删掉 TunableOp tuner。

### 4.3 版本一致性检查（H2 依赖）

- 运行时：从推理进程的 `/proc/<pid>/maps` 找到实际加载的 `libhipblaslt.so`。PyTorch wheel 可能自带一份。
- 比较方式：用 hipBLASLt 的版本 API（待确认名字，候选是 `hipblasLtGetGitRevision`）分别读出两边的构建标识；也可以比较 tuning 文件第一行的 `Git Version:` 和运行时日志里的版本。
- 待验证：所选 API 在 C 接口里存在，两边的输出可以比较。

## 5. 新内核路线（Ductile）的重新评估

继续推迟。新增两个风险：
1. `HIPBLASLT_TENSILE_LIBPATH` 换成新库后，solution index 会变。aiter 的 `AITER_CONFIG_GEMM_BF16` 里 `libtype=hipblaslt` 的行用显式 index 调用 `hipb_mm`，可能选到别的内核。aiter 侧有没有名字校验，待确认。
2. 已经 KEEP 的 override 文件需要在新库上重新生成。

重新开启的条件：M1 完成；roofline 显示剩余瓶颈仍在 hipBLASLt GEMM；目标服务不使用 aiter 的 hipBLASLt 行（或 aiter 已有名字校验）。

## 6. 里程碑与退出条件

| 里程碑 | 内容 | 退出条件 |
|---|---|---|
| M0 实测验证（不写集成代码） | 见下面的实验矩阵 | 版本匹配已确认；hipBLASLt 日志非空；override 臂端到端吞吐比无调优臂高，且超过 3 次运行的波动 |
| M1 GEKO G1 | 上游 PR | 合约测试通过；在 M0 机器上产出的文件和手工流程一致 |
| M2 Hyperloom H1–H4 | 4 个 PR，按 H1 → H2 → H3 → H4 合入 | 每个 PR 的合约测试通过；至少一个模型在完整会话中 KEEP，并能通过 recipe 复用重现 |
| M3 重新评估新内核路线 | 按第 5 节的条件 | 写出继续或放弃的结论 |

### M0 实验矩阵

固定项：同一个模型（待定，vLLM bf16 稠密模型）、同一镜像、同一 GPU、同样的 TP、并发、ISL/OSL。

| 臂 | 环境变量 | 目的 |
|---|---|---|
| 0 基线 | 无 | 参照 |
| 1 TunableOp | `PYTORCH_TUNABLEOP_*`（Hyperloom 现有流程） | 现有方案 |
| 2 GEKO override | `HIPBLASLT_TUNING_OVERRIDE_FILE` | 新方案 |
| 3 不生效检查 | 臂 1 + 臂 2 同时开 | 验证 F6：结果应和臂 1 相同 |

步骤：
1. 记录版本：容器 ROCm 版本、torch 版本、推理进程加载的 `libhipblaslt` 路径和构建标识、GEKO 所用 `hipblaslt-bench` 的构建标识。
2. 用 `HIPBLASLT_LOG_MASK=64`、`HIPBLASLT_LOG_FILE=.../hipblaslt_%i.yaml` 跑一次基线流量，确认日志非空，并统计 hipBLASLt 调用数。
3. 设置 `HIPBLASLT_TUNING_FILE` 后手工跑 `geko --search`，合并文件，每个 key 留一行。
4. 正确性运行：每个臂跑精度评估。性能运行：每个臂 3 次，报中位数和范围（tok/s、TTFT、TPOT）。正确性和性能分开跑。
5. 记录调优耗时（分钟）和每个形状的 micro 加速比。

## 7. 待你决定

1. 运行时 hipBLASLt 用哪个版本：自编 develop（≥ `ed988203a`，功能完整），还是容器自带的 release（只能在严格条件下用）？
2. M0 用哪台机器（MI300X / MI355X）、哪个模型？
3. GEKO 上游 PR（G1）和 Hyperloom PR（H1–H4）由谁提、提到哪里？

## 8. 来源

- rocm-libraries `ed988203a` "repair the tuning override path and validate entries by kernel name (#12585)"，2026-10-01
- rocm-libraries `faea76a5c` "add a versioned tuning cache store with host tests (#12586)"，2026-10-08
- hipBLASLt：`library/src/amd_detail/rocblaslt/src/UserDrivenTuningParser.cpp`、`rocblaslt_auxiliary.cpp`、`clients/common/include/argument_model.hpp`、`clients/common/include/testing_matmul.hpp`、`docs/how-to/how-to-use-hipblaslt-offline-tuning.rst`、`docs/reference/env-variables.rst`
- GEKO：`geko/search.py`、`geko/optim/optim.py`、`geko/bench/bench.py`、`geko/bench/utils.py`
- Hyperloom `a60d579`：`src/hyperloom/orchestrator/kernel/request_handlers.py`、`src/hyperloom/orchestrator/phases/kernel.py`、`src/hyperloom/orchestrator/phases/prelude.py`、`src/kernelforge/gemm_tune/`（`README.md`、`router.py`、`utils.py`、`tuners/base.py`、`tuners/vllm_dense_tunableop.py`）、`AGENTS.md`

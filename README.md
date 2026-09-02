# cpu_54 —— 同济大学计算机组成原理 54 条指令 MIPS CPU

一个在 Vivado 2016.2 下实现的 **54 条指令 MIPS 单周期 CPU**（`div/divu` 采用内部多周期迭代除法器），
已完成前仿真、单指令回归、CP0/除法专项验证、20MHz 后实现时序检查和下板 bitstream 生成。

目标器件：`xc7a100tcsg324-1`（Artix-7）

---

## 1. 仓库结构（文件夹树形图）

```text
cpu_54/
├── .gitattributes
├── .gitignore
├── LICENSE
├── README.md
│
├── CPU54实验报告.md                          # 实验报告（设计说明、波形、结论）
├── CPU54_操作时间表及控制信号逻辑表达式.xlsx   # 54 条指令操作时间表 + 控制信号逻辑表达式
│
├── cpu_54.xpr                               # Vivado 2016.2 工程文件
├── cpu_54.srcs/                             # Vivado 工程源码（RTL / 约束 / 仿真 / IP）
│   ├── constrs_1/new/
│   │   ├── icf.xdc                          # 下板约束（时钟周期 50ns = 20MHz）
│   │   ├── postsim_20ns.xdc                 # 时序扫描用约束
│   │   └── postsim_100ns.xdc
│   ├── sim_1/new/
│   │   ├── testbench_cpu54_single.v         # 前仿真 TB（老师 TB + $finish）
│   │   └── postsim_tb.v                     # 后仿真 TB
│   └── sources_1/
│       ├── new/                             # 手写 RTL（本工程核心）
│       │   ├── sccpu.v                      # CPU 主体：数据通路 + CP0 + 异常/中断入口
│       │   ├── sccontroller.v               # 控制器
│       │   ├── scalu.v                      # ALU
│       │   ├── regfile.v                    # 32×32 寄存器堆
│       │   ├── scpc.v                       # PC 寄存器
│       │   ├── scinstmem.v                  # 指令 ROM 封装（仿真）
│       │   ├── scdatamem.v                  # 数据 RAM
│       │   ├── sccomp_dataflow.v            # 前仿真顶层
│       │   ├── postsim_top.v                # 综合 / 实现 / 时序检查顶层
│       │   ├── scinstmem_board.v            # 下板用指令 ROM 封装
│       │   ├── scdatamem_postsim.v          # 后仿真用数据 RAM
│       │   ├── cpu54_board.v                # 下板：慢速 clk_en 驱动 CPU
│       │   ├── test.v                       # 下板顶层（连接 seg7x16）
│       │   ├── seg7x16.v                    # 七段数码管驱动（老师提供）
│       │   ├── cpu31_board.v                # 31 条指令阶段的遗留顶层
│       │   └── mips_54_mars_simulate.mem    # MARS 导出的 mem 镜像
│       └── ip/imem/                         # Vivado Distributed Memory Generator IP
│           ├── imem.xci / imem.xml / imem.mif / imem.dcp
│           ├── sim/imem.v                   # IP 仿真模型（读取 imem.mif）
│           ├── synth/imem.vhd
│           ├── imem_sim_netlist.v / .vhdl   # 后仿真网表
│           └── dist_mem_gen_v8_0_10/        # IP 自带 HDL 与仿真模型
│
├── datapath_diagrams/                       # 56 张数据通路图（54 条指令 + add_rtype + 总图）
├── instruction_flow_diagrams/               # 54 张指令流程图
│
├── materials/                               # 课程下发资料（第三方版权，见第 9 节）
│   ├── cpu54_frontsim/
│   │   ├── mips_54_mars_simulate_student_ForWeb_2024.coe   # 标准测试程序 COE
│   │   ├── _246tb_ex10_result.txt                          # 前仿真标准结果
│   │   ├── testbench_cpu54_single.v / testbench_cpu54_multiple.v
│   │   └── 54条指令CPU_testbench_coe和结果比对文件说明.pdf
│   └── docs/                                # 课件 PDF（实验 5 / 实验 6 / 中断 / 扩展指令）
│
├── verify/                                  # 自动化验证脚本（克隆后的主要入口）
│   ├── run_frontsim_web.ps1                 # 前仿真 + 与标准结果逐行比对
│   ├── convert_hex_to_coe.ps1               # .hex.txt -> .coe / .mif
│   ├── run_hex_result_check.ps1             # 单条 .hex.txt 用例：仿真 + 逐行比对
│   ├── run_all_hex_result_checks.ps1        # 批量跑目录下全部用例
│   ├── run_cp0_check.ps1                    # CP0 / 异常专项（break / syscall / teq / eret）
│   ├── run_div_check.ps1                    # 除法器单元测试
│   ├── run_postsim_timing.tcl               # 综合 + 实现 + 时序报告 + 后仿真网表/SDF
│   ├── run_board_bitstream_direct.tcl       # 直接生成下板 bitstream
│   ├── run_postsim_timesim.ps1              # 用网表 + SDF 跑时序仿真
│   ├── run_postsim_xsim.tcl                 # 后仿真 xsim 批处理
│   ├── run_timing_sweep.ps1                 # 多时钟周期时序扫描
│   ├── repair_imem_ip.tcl                   # 修复 / 重新生成 imem IP
│   ├── compare_web_result.ps1               # 比对仿真输出与标准结果
│   ├── testbench_cp0.v / testbench_hex_result.v / tb_div_check.v / testbench_postsim_timesim.v
│   ├── cp0test.hex.txt                      # CP0 专项测试程序
│   ├── converted/                           # 生成的 .coe / .mif（用例转换产物）
│   └── logs/                                # 每次回归的日志与摘要
│
├── tmp/                                     # 文档 / 图形生成脚本与临时文件
│   ├── create_timing_table.py
│   ├── generate_cpu54_diagrams.py
│   ├── make_add_datapath.py
│   ├── update_total_datapath.py
│   ├── postsim_current.xdc                  # 时序脚本运行时生成的约束
│   └── imem.mif.before_single_tests         # 跑回归前的 imem.mif 备份
│
├── imem.mif                                 # 当前生效的 ROM 初始化文件（脚本会覆盖它）
├── _246tb_ex10_result.txt                   # 前仿真输出（与 materials 中的标准结果比对）
├── hex_result_config.vh                     # 回归脚本生成的打印上限宏
├── hex_result_output.txt                    # 单指令回归最后一次的输出
├── timing_report.txt                        # 20MHz 时序报告
├── postsim_top.dcp                          # 综合后 checkpoint
├── postsim_timesim.v / postsim_timesim.sdf  # 后仿真网表与延时文件
│
└── cpu_54.runs/  cpu_54.sim/  cpu_54.cache/  cpu_54.hw/  cpu_54.ip_user_files/  xsim.dir/  .Xil/
    # Vivado 生成的中间目录：历史提交中曾包含副本，属于中间产物，
    # 现已由 .gitignore 忽略，克隆后重新运行工程或脚本即可再生。
```

---

## 2. 目录（TOC）

- [1. 仓库结构（文件夹树形图）](#1-仓库结构文件夹树形图)
- [2. 目录（TOC）](#2-目录toc)
- [3. 项目简介](#3-项目简介)
- [4. 功能与验证状态](#4-功能与验证状态)
- [5. 环境要求](#5-环境要求)
- [6. 安装与构建（克隆后第一次运行）](#6-安装与构建克隆后第一次运行)
- [7. 使用说明](#7-使用说明)
  - [7.1 前仿真（行为级仿真）](#71-前仿真行为级仿真)
  - [7.2 单指令回归测试](#72-单指令回归测试)
  - [7.3 CP0 / 异常专项测试](#73-cp0--异常专项测试)
  - [7.4 除法器单元验证](#74-除法器单元验证)
  - [7.5 后实现时序检查](#75-后实现时序检查)
  - [7.6 生成下板 bitstream](#76-生成下板-bitstream)
  - [7.7 使用 Vivado GUI 复现](#77-使用-vivado-gui-复现)
- [8. 目录结构说明](#8-目录结构说明)
- [9. 第三方材料声明](#9-第三方材料声明)
- [10. 许可证](#10-许可证)

---

## 3. 项目简介

本工程是同济大学《计算机组成原理》课程「实验 6：54 条指令 CPU 设计」的完整实现，
在已完成的 31 条指令 CPU 基础上扩展而来，主要特点：

- **指令集**：覆盖课程要求的 54 条 MIPS 指令，包括算术逻辑、移位、访存（`lb/lbu/lh/lhu/lw/sb/sh/sw`）、
  分支跳转、HI/LO（`mult/multu/mfhi/mthi/mflo/mtlo`）、`clz`，以及 CP0 相关指令
  （`mfc0/mtc0/break/syscall/teq/eret`）。
- **执行方式**：整体为单周期 CPU；`div/divu` 使用内部多周期迭代除法器（执行期间 PC 暂停，
  完成后写入 HI/LO 再继续），避免综合出超长组合除法器，从而满足下板时序。
- **CP0**：实现 `Status(12)`、`Cause(13)`、`EPC(14)`，并为课程 `mfc0/mtc0` 单测补充了 CP0 `8` 号寄存器读写。
- **顶层划分**：
  - `sccomp_dataflow.v`：前仿真顶层，供老师 testbench 观察 `pc` 与 `inst`；
  - `postsim_top.v`：综合 / 实现 / 时序检查顶层，暴露 `pc/inst/mem0/mem1`；
  - `test.v`：下板顶层，连接 `seg7x16.v`，数码管显示当前 PC。
- **验证体系**：`verify/` 下提供一套 PowerShell / Tcl 脚本，可一键完成「转换用例 → 编译 → 仿真 → 逐行比对」，
  以及时序检查与 bitstream 生成。

---

## 4. 功能与验证状态

| 项目 | 结果 |
| --- | --- |
| 前仿真（老师标准程序） | `web result matched 35836 lines OK` |
| 全量单指令回归（49 组用例） | `ALL_HEX_CASES_PASSED 49` |
| 除法专项（`54_div`、`33_divu`） | 各 `matched 14722 lines OK` |
| CP0 专项（`break/syscall/teq/eret`） | `CP0 CHECK PASS` |
| 后实现时序（20MHz） | Setup WNS `13.120ns`，`All user specified timing constraints are met.` |
| 下板 bitstream | `cpu_54.runs/board_direct/test.bit` 生成成功 |

标准输出说明：老师标准结果共有 `1054 × 34 = 35836` 行，其中每个结果块包含 `pc`、`instr` 和 32 个通用寄存器。

---

## 5. 环境要求

| 依赖 | 版本 / 说明 |
| --- | --- |
| 操作系统 | Windows（脚本为 PowerShell；Vivado 2016.2 官方支持 Windows / Linux，但本仓库脚本仅在 Windows 下验证过） |
| Vivado | **2016.2**（WebPACK 及以上均可），需包含 XSim 仿真器 |
| 器件支持 | Artix-7 器件库，目标器件 `xc7a100tcsg324-1` |
| PowerShell | 5.1 及以上（Windows 自带） |
| Python（可选） | 3.x，仅用于 `tmp/` 下的报告与图形生成脚本 |

> **重要**：`verify/*.ps1` 中 Vivado 安装路径**是硬编码的**，默认值为
> `C:\Xilinx\Vivado\2016.2\bin`。如果你的安装路径不同，请先按下文 [6.2](#62-配置-vivado-路径) 修改。

> 说明：本仓库不需要额外的第三方 IP，`cpu_54.srcs/sources_1/ip/imem/` 下已包含生成好的 `imem` IP
> 及其仿真模型，克隆后可直接仿真与综合。

---

## 6. 安装与构建（克隆后第一次运行）

### 6.1 获取代码

```bash
git clone https://github.com/kimi224/cpu_54.git
cd cpu_54
```

### 6.2 配置 Vivado 路径

以下脚本中第 3 行左右的 `$vivadoBin` 需要与实际安装路径一致：

- `verify/run_frontsim_web.ps1`
- `verify/run_hex_result_check.ps1`
- `verify/run_cp0_check.ps1`
- `verify/run_div_check.ps1`
- `verify/run_postsim_timesim.ps1`
- `verify/run_timing_sweep.ps1`（变量名为 `$vivado`）

将

```powershell
$vivadoBin = "C:\Xilinx\Vivado\2016.2\bin"
```

改为你的实际路径，例如：

```powershell
$vivadoBin = "D:\Xilinx\Vivado\2016.2\bin"
```

### 6.3 第一次验证（推荐按此顺序）

```powershell
# 1) 前仿真：跑老师标准程序并与标准结果逐行比对
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_frontsim_web.ps1

# 2) CP0 / 异常专项（不需要外部用例文件）
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_cp0_check.ps1

# 3) 除法器单元测试（不需要外部用例文件）
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_div_check.ps1
```

三条命令都必须在**仓库根目录**执行（脚本内部使用相对路径）。

### 6.4 打开 Vivado 工程（可选）

1. 启动 Vivado 2016.2 → `Open Project` → 选择仓库根目录下的 `cpu_54.xpr`。
2. 首次打开若提示 IP 状态异常，可在 Vivado Tcl Console 中执行：

```tcl
source verify/repair_imem_ip.tcl
```

3. 若 Vivado 报告 `imem` IP 需要升级，按提示 `Upgrade` 后重新 `Generate Output Products`。

---

## 7. 使用说明

> 所有命令均在**仓库根目录**执行；若系统限制了脚本执行，统一加 `-ExecutionPolicy Bypass`。

### 7.1 前仿真（行为级仿真）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_frontsim_web.ps1
```

脚本行为：

1. 把 `cpu_54.srcs/sources_1/ip/imem/imem.mif` 复制到仓库根目录 `imem.mif`；
2. 依次执行 `xvlog` → `xelab` → `xsim -runall`（TB 顶层：`_246tb_ex10_tb`）；
3. 调用 `verify/compare_web_result.ps1` 与 `materials/cpu54_frontsim/_246tb_ex10_result.txt` 逐行比对。

预期输出：

```text
web result matched 35836 lines OK
```

### 7.2 单指令回归测试

课程资料目录 `54条CPUtest指令示例和测试说明` 中的 `.hex.txt`（每行一条 32 位机器码）与
`.result.txt`（MARS 风格标准输出）**未随本仓库分发**（属课程资料，见第 9 节）。
克隆者需自备该目录，并把它作为 `-CaseDir` 传入。

**跑单个用例：**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_hex_result_check.ps1 `
  -HexPath  "<用例目录>\54_div.hex.txt" `
  -ExpectedPath "<用例目录>\54_div.result.txt"
```

预期输出：

```text
hex result matched 14722 lines OK: 54_div
```

**跑目录下全部用例（49 组）：**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_all_hex_result_checks.ps1 `
  -CaseDir "<用例目录>"
```

预期输出：

```text
ALL_HEX_CASES_PASSED 49
```

摘要写入 `verify/logs/hex_result_summary.txt`，每个用例的详细日志在 `verify/logs/*.log`。

> 用例目录中不是 54 个物理文件，而是 49 组测试，部分文件覆盖多条指令（如 `16.26_lwsw`、
> `42.45_mfc0mtc0`）。`syscall`、`break`、`teq`、`eret` 不按 MARS 内置系统调用语义比对，
> 由 [7.3](#73-cp0--异常专项测试) 的 CP0 专项测试覆盖。

**用例格式转换（.hex.txt → .coe / .mif）：**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\convert_hex_to_coe.ps1 `
  -HexPath "<用例目录>\54_div.hex.txt" `
  -CoePath verify\converted\54_div.coe `
  -MifPath verify\converted\54_div.mif
```

- `.coe`：Vivado GUI 重新配置 ROM IP 时使用的标准初始化文件；
- `.mif`：当前 `imem` 仿真模型直接读取的文件，内容为 32 位二进制行（脚本会覆盖根目录 `imem.mif`）。

### 7.3 CP0 / 异常专项测试

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_cp0_check.ps1
```

脚本把 `verify/cp0test.hex.txt` 转成 `imem.mif` 后运行 `verify/testbench_cp0.v`，
验证 `break/syscall/teq` 进入异常、`Cause` 低 8 位分别为 `0x24/0x20/0x34`、
`eret` 返回异常指令的下一条，最终 `$10/$11/$12 = ffffffff`。
结束后会**自动恢复**根目录的 `imem.mif`。

预期输出：

```text
CP0 CHECK PASS: break/syscall/teq/eret handlers executed
```

> `CP0test.txt` 的异常入口布局为「前两条跳转 + 空槽」，`0x00400008` 才是真正的 `j _exceptions`。
> 本 CPU 未实现 MIPS 延迟槽，因此该 testbench 中设置 `EXC_ENTRY = 32'h00400008`。

### 7.4 除法器单元验证

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_div_check.ps1
```

直接对 `sccpu.v` 中的迭代除法器做单元测试（TB：`verify/tb_div_check.v`），不需要外部用例文件。

### 7.5 后实现时序检查

```powershell
$env:CPU54_PERIOD_NS = "50.000"
& "C:\Xilinx\Vivado\2016.2\bin\vivado.bat" -mode batch -source verify\run_postsim_timing.tcl
```

- `CPU54_PERIOD_NS` 为时钟周期（ns），不设置时默认 `20.000`；下板约束为 `50.000`（20MHz）。
- 生成的临时约束写入 `tmp/postsim_current.xdc`。

生成文件：

| 文件 | 说明 |
| --- | --- |
| `timing_report.txt` | 时序汇总报告 |
| `timing_paths.txt` | 关键路径明细 |
| `utilization_report.txt` | 资源利用率 |
| `postsim_top.dcp` | 综合后 checkpoint |
| `postsim_timesim.v` / `postsim_timesim.sdf` | 后仿真网表与延时文件 |

通过判据（20MHz）：

```text
Setup Worst Slack = 13.120ns
All user specified timing constraints are met.
```

时序设计说明：组合乘法/除法原本会形成 `pc → imem → regfile → HI/LO` 的超长路径，
10MHz 下也曾出现负 slack。解决方式是保留可综合的乘法实现，并把 `div/divu` 改为内部多周期迭代除法器，
最终 20MHz 通过。

### 7.6 生成下板 bitstream

```powershell
& "C:\Xilinx\Vivado\2016.2\bin\vivado.bat" -mode batch -source verify\run_board_bitstream_direct.tcl
```

预期输出：

```text
BITSTREAM=<仓库路径>\cpu_54.runs\board_direct\test.bit
All user specified timing constraints are met.
```

顶层为 `test.v`，使用约束 `cpu_54.srcs/constrs_1/new/icf.xdc`：

```tcl
create_clock -period 50.000 -name clk_pin -waveform {0.000 25.000} [get_ports clk_in]
```

**下板正确现象：**

- 按下 / 拨到 reset 时，数码管回到起始 PC 附近；
- 松开 reset 后数码管显示当前 PC，约每 0.5 秒更新一次（约 2 步/秒），
  因为 `cpu54_board.v` 中 `CPU_STEP_DIVISOR = 50_000_000`，输入时钟 100MHz；
- 遇到 `div/divu` 等多周期指令时 PC 会短暂停住，这是为满足时序而做的正常设计；
- 程序跑到测试末尾循环时 PC 稳定在循环地址，也属正常。

### 7.7 使用 Vivado GUI 复现

**前仿真**

1. `Open Project` → 选择 `cpu_54.xpr`；
2. `Design Sources` 中确认包含：`sccpu.v`、`regfile.v`、`scdatamem.v`、`scinstmem.v`、
   `sccomp_dataflow.v`、`imem.xci`；
3. `Simulation Sources` 中确认包含 `testbench_cpu54_single.v`；
4. 若 IP 未生成，右键 `imem.xci` → `Generate Output Products`；
5. 如需重新导入标准程序：双击 `imem.xci` → 初始化文件选择
   `materials/cpu54_frontsim/mips_54_mars_simulate_student_ForWeb_2024.coe` → 重新生成；
6. `Run Simulation` → `Run Behavioral Simulation`；
7. 仿真输出为根目录 `_246tb_ex10_result.txt`，用 `verify/compare_web_result.ps1` 比对。

**时序检查**

1. 打开 `cpu_54.xpr`，确认 `postsim_top.v` 已加入 `Design Sources` 并 `Set as Top`；
2. 确认约束文件为 `cpu_54.srcs/constrs_1/new/icf.xdc`；
3. `Run Synthesis` → `Run Implementation` → `Open Implemented Design`；
4. `Reports` → `Timing` → `Report Timing Summary`，保存为 `timing_report.txt`；
5. 检查报告中是否出现 `All user specified timing constraints are met.`

> 后仿真说明：仓库提供了 `postsim_timesim.v` / `.sdf` 与 `verify/run_postsim_timesim.ps1`，
> 但在原开发机上 `xelab` 静态展开超过 10 分钟仍未产出 snapshot，**这不是时序失败**，
> 时序报告本身已通过。若需复现，可在 GUI 中选择
> `Run Simulation → Run Post-Implementation Timing Simulation`，仿真顶层选 `postsim_tb.v`。

---

## 8. 目录结构说明

| 路径 | 内容 |
| --- | --- |
| `cpu_54.srcs/sources_1/new/` | 手写 RTL：CPU 主体、控制器、ALU、寄存器堆、存储器、三个顶层（前仿真 / 后仿真 / 下板） |
| `cpu_54.srcs/sources_1/ip/imem/` | Vivado `Distributed Memory Generator` IP，宽 32 位、深 2048，初始化来自课程下发的 `.coe` |
| `cpu_54.srcs/sim_1/new/` | 前仿真 TB 与后仿真 TB |
| `cpu_54.srcs/constrs_1/new/` | 下板约束（20MHz）与时序扫描用约束 |
| `verify/` | 全部验证脚本、辅助 testbench、转换产物与日志 |
| `materials/` | 课程下发资料（老师 TB、标准 COE、标准结果、课件 PDF） |
| `datapath_diagrams/`、`instruction_flow_diagrams/` | 54 条指令的数据通路图与流程图，以及一张总数据通路图 |
| `tmp/` | 报告 / 图形生成脚本与脚本运行时的临时文件 |
| 根目录 `imem.mif` | 当前生效的 ROM 初始化文件；`run_hex_result_check.ps1`、`run_cp0_check.ps1` 会临时覆盖它 |

---

## 9. 第三方材料声明

仓库本体（RTL、脚本、文档、图表）以 MIT 许可证发布，见 [LICENSE](LICENSE)。

以下内容**不在本仓库许可证覆盖范围内**，版权归原作者（课程教师 / 教材作者）所有，
仅作为课程作业配套资料随仓库一并保存，请勿二次分发或用于商业用途：

- `materials/` 目录下全部内容：老师 testbench（`testbench_cpu54_single.v` / `testbench_cpu54_multiple.v`）、
  标准测试程序 COE、标准结果文件、课件 PDF；
- `cpu_54.srcs/sources_1/new/seg7x16.v`：课程提供的七段数码管驱动；
- `cpu_54.srcs/sources_1/ip/imem/` 中由 Vivado 生成的部分文件：Xilinx IP 及其生成代码受
  Xilinx 工具许可约束；
- `cpu_54.srcs/constrs_1/new/icf.xdc`：基于课程提供的约束文件修改（时钟周期已改为 50ns）。

如你 fork 本仓库用于学习或二次开发，请自行替换或移除上述第三方材料。

---

## 10. 许可证

本仓库的自有代码与文档采用 **MIT License**，详见 [LICENSE](LICENSE)。

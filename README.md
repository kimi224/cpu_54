# cpu_54

同济大学计算机组成原理 54 条指令 CPU 实验工程。本工程基于已经完成的 31 条指令 CPU 继续开发，当前完成了前仿真、单指令回归、除法/CP0 专项验证、后实现时序检查和下板 bitstream 生成，并在 Vivado 2016.2 下通过 20MHz 时序约束。

## 当前状态

- CPU 类型：54 条指令 MIPS CPU。
- 主体实现：以单周期执行为主，`div/divu` 使用内部多周期迭代除法器以保证可综合和可下板时序。
- 前仿真：使用 Vivado XSim 运行老师 `testbench_cpu54_single.v`，输出与 `_246tb_ex10_result.txt` 逐行一致。
- 除法专项验证：老师 `54_div.hex.txt/.result.txt`、`33_divu.hex.txt/.result.txt` 均通过。
- 全量单指令验证：`54条CPUtest指令示例和测试说明` 下 49 组 `.hex.txt/.result.txt` 全部通过，覆盖 54 条指令。
- CP0 专项验证：按 `CP0test.txt` 自行组织 `break/syscall/teq/eret` 异常处理程序，验证 `$10/$11/$12`、`Status/Cause/EPC` 和 `eret` 返回，已通过。
- 后实现时序：20MHz 通过，`timing_report.txt` 中 setup 最差 slack 为 `13.120ns`，并显示 `All user specified timing constraints are met.`
- 下板 bitstream：已生成 `cpu_54.runs/board_direct/test.bit`，下板顶层为 `test.v`，七段数码管显示当前 PC；默认约每 0.5 秒执行一步（约 2 步/秒）。
- 文档：`CPU54实验报告.md`、`CPU54_操作时间表及控制信号逻辑表达式.xlsx`，以及 `datapath_diagrams/`、`instruction_flow_diagrams/` 图集。

## 目录结构

```text
cpu_54/
|-- README.md
|-- cpu_54.xpr
|-- timing_report.txt
|-- postsim_top.dcp
|-- postsim_timesim.v
|-- postsim_timesim.sdf
|-- datapath_diagrams/
|   |-- cpu54_total_datapath.png
|   `-- 每条指令数据通路图（共 54 张）
|-- instruction_flow_diagrams/
|   `-- 每条指令流程图（共 54 张）
|-- cpu_54.srcs/
|   |-- sources_1/new/
|   |   `-- CPU RTL、前/后仿真顶层、下板顶层和七段数码管模块
|   |-- sources_1/ip/imem/
|   |   `-- imem.xci、imem.mif、imem.v 和 IP 仿真模型
|   |-- sim_1/new/testbench_cpu54_single.v
|   `-- constrs_1/new/icf.xdc
|-- materials/cpu54_frontsim/
|   `-- 老师 testbench、COE 和标准结果文件
`-- verify/
    `-- Vivado XSim 仿真、单指令回归、CP0、除法、后仿真和下板脚本
```

## 主要文件说明

`cpu_54.srcs/sources_1/new/sccpu.v`  
CPU 主体。支持 54 条指令实验需要的算术逻辑、移位、访存、分支跳转、HI/LO、CP0、中断异常入口和 `eret`。CP0 支持 `Status(12)`、`Cause(13)`、`EPC(14)`，并为老师 `mfc0/mtc0` 单测补充了 CP0 `8` 号寄存器读写。为解决时序问题，`div/divu` 改为内部多周期迭代除法器：执行除法时 PC 暂停，完成后写入 HI/LO 并继续执行。这样不会综合出超长组合除法器。

`cpu_54.srcs/sources_1/new/sccomp_dataflow.v`  
前仿真顶层，实例化 `sccpu`、`scinstmem`、`scdatamem`，对外提供老师 testbench 观察的 `pc` 和 `inst`。

`cpu_54.srcs/sources_1/new/postsim_top.v`  
后实现/时序检查顶层。用于综合、布局布线、生成 `timing_report.txt`、`postsim_timesim.v` 和 `postsim_timesim.sdf`。

`cpu_54.srcs/sources_1/new/scinstmem.v`  
指令 ROM 封装，内部实例化 Vivado `imem` IP。地址换算为 `word_addr = addr[12:2]`。

`CPU54实验报告.md`、`datapath_diagrams/`、`instruction_flow_diagrams/`  
实验报告、54 条指令的单条数据通路图/流程图以及总数据通路图。

`CPU54_操作时间表及控制信号逻辑表达式.xlsx`  
包含 54 条指令操作时间表和控制信号逻辑表达式表。普通指令为 `T0` 单周期，`div/divu` 为 `T0` 启动、`T1-T32` 迭代、`T33` 提交。

`cpu_54.srcs/sources_1/ip/imem/imem.xci`  
Vivado `Distributed Memory Generator` IP。宽度 32 位，深度 2048，初始化来自老师下发的 `.coe`，生成的 `imem.mif` 与 `imem.v` 一起用于仿真、后仿真和下板。

`cpu_54.xpr`  
Vivado 2016.2 工程文件，器件为 `xc7a100tcsg324-1`，工程目标仿真器为 Vivado XSim，默认下板顶层为 `test`。

`cpu_54.srcs/sim_1/new/testbench_cpu54_single.v`  
老师单周期前仿真 testbench 副本，保留文件名。工程中只增加了 `$finish`，方便 `xsim -runall` 自动结束。

`verify/convert_hex_to_coe.ps1`  
把老师单指令测试里的 `.hex.txt` 转成标准 Vivado `.coe`。同时可生成 IP 仿真模型读取的二进制 `.mif`。

`verify/run_hex_result_check.ps1`  
读取 `.hex.txt` 和对应 `.result.txt`，自动转换、仿真并逐行比对。脚本兼容 MARS 风格跳转 PC 显示、分支实际执行条数、以及 `add/sub` 溢出测试末尾只给出部分结果块的格式。

`verify/run_all_hex_result_checks.ps1`  
遍历老师 `54条CPUtest指令示例和测试说明` 目录下全部 `.hex.txt/.result.txt`，逐个调用 `run_hex_result_check.ps1`。本轮结果为 `ALL_HEX_CASES_PASSED 49`，摘要保存在 `verify/logs/hex_result_summary.txt`。

`verify/run_cp0_check.ps1`  
把 `verify/cp0test.hex.txt` 临时写入 `imem.mif`，运行 `testbench_cp0.v`。该测试按老师 `CP0test.txt` 的含义验证 `break/syscall/teq` 进入异常处理、`Cause` 低 8 位分别为 `0x24/0x20/0x34`、`eret` 返回异常指令后一条，且最终 `$10/$11/$12 = ffffffff`。

`verify/run_postsim_timing.tcl`  
Vivado batch 脚本，执行综合、布局布线、时序报告、利用率报告、时序仿真网表和 SDF 生成。

`cpu_54.srcs/sources_1/new/cpu54_board.v` 和 `test.v`  
下板顶层。`cpu54_board.v` 用慢速 `clk_en` 驱动 CPU，`test.v` 连接老师给的 `seg7x16.v`，当前显示数据为 PC，便于观察程序是否在执行。

## 前仿真

在工程根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_frontsim_web.ps1
```

最终结果：

```text
web result matched 35836 lines OK
```

说明：老师标准输出共有 `1054 * 34 = 35836` 行，每个结果块包含 `pc`、`instr` 和 32 个通用寄存器。

## `.hex.txt` 转 `.coe`

老师在 `54条CPUtest指令示例和测试说明` 中提供了很多 `.hex.txt` 和 `.result.txt`。`.hex.txt` 每行是一条 32 位十六进制机器码，转换成 Vivado 标准 `.coe` 的格式如下：

```text
memory_initialization_radix = 16;
memory_initialization_vector =
00000000,
20017fff,
...
00000000;
```

转换命令示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\convert_hex_to_coe.ps1 `
  -HexPath "C:\大学\计算机组成原理\实验指导书\54条指令CPU实验相关文档\54条CPUtest指令示例和测试说明\54_div.hex.txt" `
  -CoePath verify\converted\54_div.coe `
  -MifPath verify\converted\54_div.mif
```

注意：`.coe` 是 Vivado GUI 重新配置 ROM IP 时使用的标准初始化文件；`imem.mif` 是当前 `imem` 仿真模型直接读取的文件，内容为 32 位二进制行。

## 除法专项验证

老师单独提供的除法测试使用 `.hex.txt/.result.txt`，目标结果比对文件是 `.result.txt`。本工程已加入自动比对脚本。

有符号除法：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_hex_result_check.ps1 `
  -HexPath "C:\大学\计算机组成原理\实验指导书\54条指令CPU实验相关文档\54条CPUtest指令示例和测试说明\54_div.hex.txt" `
  -ExpectedPath "C:\大学\计算机组成原理\实验指导书\54条指令CPU实验相关文档\54条CPUtest指令示例和测试说明\54_div.result.txt"
```

通过结果：

```text
hex result matched 14722 lines OK: 54_div
```

无符号除法：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_hex_result_check.ps1 `
  -HexPath "C:\大学\计算机组成原理\实验指导书\54条指令CPU实验相关文档\54条CPUtest指令示例和测试说明\33_divu.hex.txt" `
  -ExpectedPath "C:\大学\计算机组成原理\实验指导书\54条指令CPU实验相关文档\54条CPUtest指令示例和测试说明\33_divu.result.txt"
```

通过结果：

```text
hex result matched 14722 lines OK: 33_divu
```

这里的 testbench 使用“指令执行完成后打印”的 MARS 风格，同时只在 PC 改变时打印，因此可兼容多周期除法等待周期。

## 全量单指令与 CP0 验证

全量 MARS 风格单指令测试：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_all_hex_result_checks.ps1 `
  -CaseDir "C:\大学\计算机组成原理\实验指导书\54条指令CPU实验相关文档\54条CPUtest指令示例和测试说明"
```

本轮通过结果：

```text
ALL_HEX_CASES_PASSED 49
```

说明：该目录中不是 54 个物理 `.hex.txt` 文件，而是 49 组测试，其中部分文件覆盖多条指令，例如 `16.26_lwsw`、`42.45_mfc0mtc0`。`syscall`、`break`、`teq`、`eret` 不按 MARS 内置系统调用标准比对，使用下面的 CP0 专项语义测试。

CP0 专项测试：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File verify\run_cp0_check.ps1
```

本轮通过结果：

```text
CP0 CHECK PASS: break/syscall/teq/eret handlers executed
```

`CP0test.txt` 中异常入口布局为前两条跳转加空槽：`0x00400004` 是 `nop`，`0x00400008` 才是 `j _exceptions`。本 CPU 没有实现 MIPS 延迟槽，因此 CP0 专项 testbench 设置 `EXC_ENTRY = 32'h00400008` 来匹配该测试程序的异常处理入口。

## 后实现时序检查

20MHz 时序检查命令：

```powershell
$env:CPU54_PERIOD_NS = "50.000"
& "C:\Xilinx\Vivado\2016.2\bin\vivado.bat" -mode batch -source verify\run_postsim_timing.tcl
```

生成文件：

- `timing_report.txt`
- `timing_paths.txt`
- `utilization_report.txt`
- `postsim_top.dcp`
- `postsim_timesim.v`
- `postsim_timesim.sdf`

已备份通过版本：

- `timing_report_20MHz_pass.txt`
- `timing_paths_20MHz_pass.txt`
- `utilization_report_20MHz_pass.txt`

最终时序结果：

```text
Setup Worst Slack = 13.120ns
Hold Worst Slack  = 0.004ns
TNS(ns) = 0.000
All user specified timing constraints are met.
```

本轮优化前，组合乘法/除法会形成 `pc -> imem -> regfile -> HI/LO` 的超长路径，10MHz 也曾出现负 slack。解决方式是保留乘法可综合实现，并把 `div/divu` 改成内部多周期迭代除法器，避免综合出 32 位组合除法器。最终 20MHz 通过。

## Vivado GUI 前仿真复现

1. 打开 Vivado，选择 `Open Project`，打开 `cpu_54.xpr`。
2. 在 `Sources` 面板确认以下文件在 `Design Sources`：
   - `sccpu.v`
   - `regfile.v`
   - `scdatamem.v`
   - `scinstmem.v`
   - `sccomp_dataflow.v`
   - `imem.xci`
3. 在 `Simulation Sources` 中确认有：
   - `testbench_cpu54_single.v`
4. 若 IP 没生成，右键 `imem.xci`，选择 `Generate Output Products`。
5. 若要重新导入老师正式 `.coe`：
   - 双击 `imem.xci`
   - 找到初始化文件选项，选择 `materials/cpu54_frontsim/mips_54_mars_simulate_student_ForWeb_2024.coe`
   - 保存后重新 `Generate Output Products`
6. 在 Flow Navigator 中点击 `Run Simulation` -> `Run Behavioral Simulation`。
7. 仿真结束后查看工程根目录或仿真目录中的 `_246tb_ex10_result.txt`。
8. 用 `verify/compare_web_result.ps1` 或手动 diff 与 `materials/cpu54_frontsim/_246tb_ex10_result.txt` 比对。

## Vivado GUI 时序检查复现

1. 打开 `cpu_54.xpr`。
2. 确认 `postsim_top.v` 已加入 `Design Sources`。
3. 确认约束文件 `cpu_54.srcs/constrs_1/new/icf.xdc` 存在，20MHz 约束为：

```tcl
create_clock -period 50.000 -name clk_pin -waveform {0.000 25.000} [get_ports clk_in]
set_input_delay -clock [get_clocks *] 1.000 [get_ports reset]
set_output_delay -clock [get_clocks *] 0.000 [get_ports -filter { NAME =~  "*" && DIRECTION == "OUT" }]
```

4. 在 `Sources` 中右键 `postsim_top.v`，设为综合顶层。
5. 点击 `Run Synthesis`。
6. 综合完成后点击 `Run Implementation`。
7. 实现完成后点击 `Open Implemented Design`。
8. 在菜单中选择 `Reports` -> `Timing` -> `Report Timing Summary`。
9. 保存报告到工程根目录，命名为 `timing_report.txt`。
10. 检查报告中是否出现：

```text
All user specified timing constraints are met.
```

命令行脚本 `verify/run_postsim_timing.tcl` 做的是同一件事，只是更容易复现实验结果和保存报告。

## 后仿真复现

后仿真使用 `postsim_top.v` 作为综合/实现顶层，不是下板顶层；下板使用 `test.v`。二者共用 CPU、指令 ROM 和数据 RAM，但用途不同：

- `postsim_top.v`：暴露 `pc/inst/mem0/mem1`，便于时序报告和 timing simulation。
- `test.v`：连接七段数码管，只保留板上真实 IO。

命令行生成后仿真网表和 SDF：

```powershell
$env:CPU54_PERIOD_NS = "50.000"
& "C:\Xilinx\Vivado\2016.2\bin\vivado.bat" -mode batch -source verify\run_postsim_timing.tcl
```

本轮已生成：

- `postsim_top.dcp`
- `postsim_timesim.v`
- `postsim_timesim.sdf`

我也加入了 `verify\run_postsim_timesim.ps1`，它直接用上述 timing netlist/SDF 跑 xsim。当前机器上 `xelab` 在静态展开完成后超过 10 分钟仍未产生 snapshot，因此按本次约定停止；这不是时序失败，时序报告已经通过。若在 Vivado GUI 中复现后仿真：

1. 打开 `cpu_54.xpr`。
2. 确认 `postsim_top.v` 设为综合顶层。
3. Run Synthesis -> Run Implementation。
4. Open Implemented Design。
5. Flow Navigator 选择 `Run Simulation` -> `Run Post-Implementation Timing Simulation`。
6. 若 Vivado 提示仿真顶层，选择 `postsim_tb.v` 或新建一个只驱动 `clk_in/reset`、观察 `pc/inst/mem0/mem1` 的 testbench。
7. 正常现象：仿真能加载 `postsim_timesim.sdf`，波形中 `pc` 按程序流变化，`inst` 与 ROM 输出对应，没有 X 大面积扩散。

## 下板与 Bitstream

下板约束文件为 `cpu_54.srcs/constrs_1/new/icf.xdc`，来自老师 `icf.xdc`，时钟周期已改为 50ns：

```tcl
create_clock -period 50.000 -name clk_pin -waveform {0.000 25.000} [get_ports clk_in]
```

命令行生成 bitstream：

```powershell
& "C:\Xilinx\Vivado\2016.2\bin\vivado.bat" -mode batch -source verify\run_board_bitstream_direct.tcl
```

本轮生成结果：

```text
BITSTREAM=D:/computer_composition/cpu_54/cpu_54.runs/board_direct/test.bit
All user specified timing constraints are met.
```

下板 GUI 复现：

1. 打开 `cpu_54.xpr`。
2. 确认以下文件加入 Design Sources：`sccpu.v`、`regfile.v`、`scdatamem.v`、`scinstmem.v`、`cpu54_board.v`、`seg7x16.v`、`test.v`、`imem.xci`。
3. 确认约束文件为 `cpu_54.srcs/constrs_1/new/icf.xdc`。
4. 右键 `test.v`，选择 `Set as Top`。
5. 若需要重新导入下板程序，双击 `imem.xci`，初始化文件选择 `materials/cpu54_frontsim/mips_54_mars_simulate_student_ForWeb_2024.coe`，然后 `Generate Output Products`。
6. Run Synthesis -> Run Implementation -> Generate Bitstream。
7. Open Hardware Manager，连接板卡，Program Device，选择生成的 `test.bit`。

下板正确现象：

- 复位按键有效：按住或拨到 reset 时，七段数码管显示回到起始 PC 附近。
- 松开 reset 后，七段数码管显示当前 PC，约每 0.5 秒更新一次（约 2 步/秒），因为 `cpu54_board.v` 中默认 `CPU_STEP_DIVISOR = 50_000_000`，输入时钟为 100MHz。
- PC 应按程序流前进，不应全灭、全亮、长时间固定在 reset 之外的随机值。
- 遇到 `div/divu` 等多周期指令时，PC 会短暂停住，这是本设计为满足时序而实现的正常现象。
- 使用当前网站 `.coe` 时，程序最终可能进入测试程序末尾循环；此时 PC 稳定在某个循环地址是正常的，不代表板子坏了。

## 验证记录

最终代码完成后，已执行：

```text
正式前仿真：web result matched 35836 lines OK
全量单指令：ALL_HEX_CASES_PASSED 49
CP0 专项：CP0 CHECK PASS: break/syscall/teq/eret handlers executed
20MHz 时序：setup slack 13.120ns，All user specified timing constraints are met.
下板 bitstream：cpu_54.runs/board_direct/test.bit，bitgen completed successfully.
```

$ErrorActionPreference = "Stop"

$vivadoBin = "C:\Xilinx\Vivado\2016.2\bin"
$sources = @(
    "cpu_54.srcs\sources_1\ip\imem\dist_mem_gen_v8_0_10\simulation\dist_mem_gen_v8_0.v",
    "cpu_54.srcs\sources_1\ip\imem\sim\imem.v",
    "cpu_54.srcs\sources_1\new\regfile.v",
    "cpu_54.srcs\sources_1\new\scdatamem.v",
    "cpu_54.srcs\sources_1\new\scinstmem.v",
    "cpu_54.srcs\sources_1\new\sccpu.v",
    "cpu_54.srcs\sources_1\new\sccomp_dataflow.v",
    "cpu_54.srcs\sim_1\new\testbench_cpu54_single.v"
)

Copy-Item -Force "cpu_54.srcs\sources_1\ip\imem\imem.mif" "imem.mif"

& "$vivadoBin\xvlog.bat" @sources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$vivadoBin\xelab.bat" _246tb_ex10_tb -snapshot tb_cpu54_single_behav
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$vivadoBin\xsim.bat" tb_cpu54_single_behav -runall
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& powershell -NoProfile -ExecutionPolicy Bypass -File "verify\compare_web_result.ps1"

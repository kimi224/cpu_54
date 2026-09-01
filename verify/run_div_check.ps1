$ErrorActionPreference = "Stop"

$vivadoBin = "C:\Xilinx\Vivado\2016.2\bin"
$sources = @(
    "cpu_54.srcs\sources_1\new\regfile.v",
    "cpu_54.srcs\sources_1\new\sccpu.v",
    "verify\tb_div_check.v"
)

& "$vivadoBin\xvlog.bat" @sources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$vivadoBin\xelab.bat" tb_div_check -snapshot tb_div_check_behav
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$vivadoBin\xsim.bat" tb_div_check_behav -runall
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

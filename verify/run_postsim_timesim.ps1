$ErrorActionPreference = "Stop"

$vivadoBin = "C:\Xilinx\Vivado\2016.2\bin"
New-Item -ItemType Directory -Force -Path "tmp" | Out-Null
Remove-Item -Force -ErrorAction SilentlyContinue "tmp\postsim_result.txt"

$sources = @(
    "postsim_timesim.v",
    "verify\testbench_postsim_timesim.v"
)

& "$vivadoBin\xvlog.bat" @sources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$vivadoBin\xelab.bat" --debug off --relax --mt 4 --maxdelay -L simprims_ver -L unisims_ver -L secureip testbench_postsim_timesim glbl -snapshot testbench_postsim_timesim
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$vivadoBin\xsim.bat" testbench_postsim_timesim -runall
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (!(Test-Path -LiteralPath "tmp\postsim_result.txt")) {
    throw "postsim result was not generated"
}

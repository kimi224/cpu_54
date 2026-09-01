$ErrorActionPreference = "Stop"

$vivadoBin = "C:\Xilinx\Vivado\2016.2\bin"
$convertedDir = "verify\converted"
New-Item -ItemType Directory -Force -Path $convertedDir | Out-Null

try {
    powershell -NoProfile -ExecutionPolicy Bypass -File "verify\convert_hex_to_coe.ps1" `
        -HexPath "verify\cp0test.hex.txt" `
        -CoePath (Join-Path $convertedDir "cp0test.coe") `
        -MifPath (Join-Path $convertedDir "cp0test.mif")

    Copy-Item -Force (Join-Path $convertedDir "cp0test.mif") "imem.mif"

    $sources = @(
        "cpu_54.srcs\sources_1\ip\imem\dist_mem_gen_v8_0_10\simulation\dist_mem_gen_v8_0.v",
        "cpu_54.srcs\sources_1\ip\imem\sim\imem.v",
        "cpu_54.srcs\sources_1\new\regfile.v",
        "cpu_54.srcs\sources_1\new\scdatamem.v",
        "cpu_54.srcs\sources_1\new\scinstmem.v",
        "cpu_54.srcs\sources_1\new\sccpu.v",
        "cpu_54.srcs\sources_1\new\sccomp_dataflow.v",
        "verify\testbench_cp0.v"
    )

    & "$vivadoBin\xvlog.bat" @sources
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & "$vivadoBin\xelab.bat" testbench_cp0 -snapshot testbench_cp0_behav
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & "$vivadoBin\xsim.bat" testbench_cp0_behav -runall
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Copy-Item -Force "cpu_54.srcs\sources_1\ip\imem\imem.mif" "imem.mif"
}

param(
    [Parameter(Mandatory = $true)][string]$HexPath,
    [Parameter(Mandatory = $true)][string]$ExpectedPath
)

$ErrorActionPreference = "Stop"

$vivadoBin = "C:\Xilinx\Vivado\2016.2\bin"
$convertedDir = "verify\converted"
New-Item -ItemType Directory -Force -Path $convertedDir | Out-Null

$baseName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileNameWithoutExtension($HexPath))
$coePath = Join-Path $convertedDir "$baseName.coe"
$mifPath = Join-Path $convertedDir "$baseName.mif"

powershell -NoProfile -ExecutionPolicy Bypass -File "verify\convert_hex_to_coe.ps1" -HexPath $HexPath -CoePath $coePath -MifPath $mifPath
Copy-Item -Force $mifPath "imem.mif"
$expectedLines = Get-Content -LiteralPath $ExpectedPath
$printLimit = ($expectedLines | Where-Object { $_.Trim() -match '^pc:' }).Count
if ($printLimit -le 0) {
    throw "expected result contains no pc lines: $ExpectedPath"
}
Set-Content -LiteralPath "hex_result_config.vh" -Value ('`define HEX_RESULT_PRINT_LIMIT ' + $printLimit) -Encoding ASCII

$sources = @(
    "cpu_54.srcs\sources_1\ip\imem\dist_mem_gen_v8_0_10\simulation\dist_mem_gen_v8_0.v",
    "cpu_54.srcs\sources_1\ip\imem\sim\imem.v",
    "cpu_54.srcs\sources_1\new\regfile.v",
    "cpu_54.srcs\sources_1\new\scdatamem.v",
    "cpu_54.srcs\sources_1\new\scinstmem.v",
    "cpu_54.srcs\sources_1\new\sccpu.v",
    "cpu_54.srcs\sources_1\new\sccomp_dataflow.v",
    "verify\testbench_hex_result.v"
)

& "$vivadoBin\xvlog.bat" @sources
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$vivadoBin\xelab.bat" testbench_hex_result -snapshot testbench_hex_result_behav
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& "$vivadoBin\xsim.bat" testbench_hex_result_behav -runall
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$actual = Get-Content -LiteralPath "hex_result_output.txt"
$expected = $expectedLines
if ($actual.Count -lt $expected.Count) {
    throw "line count too short: actual=$($actual.Count), expected=$($expected.Count)"
}
if (($actual.Count -ne $expected.Count) -and (($expected.Count % 34) -eq 0)) {
    throw "line count differs: actual=$($actual.Count), expected=$($expected.Count)"
}

for ($i = 0; $i -lt $actual.Count; $i++) {
    if ($i -ge $expected.Count) {
        break
    }
    if ($actual[$i].Trim().ToLowerInvariant() -ne $expected[$i].Trim().ToLowerInvariant()) {
        $line = $i + 1
        throw "mismatch at line ${line}: actual='$($actual[$i])' expected='$($expected[$i])'"
    }
}

Write-Host "hex result matched $($actual.Count) lines OK: $baseName"

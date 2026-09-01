param(
    [Parameter(Mandatory = $true)][string]$CaseDir
)

$ErrorActionPreference = "Stop"

$logDir = "verify\logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$summaryPath = Join-Path $logDir "hex_result_summary.txt"
$cases = Get-ChildItem -LiteralPath $CaseDir -Filter "*.hex.txt" | Sort-Object Name

if ($cases.Count -eq 0) {
    throw "No *.hex.txt files found in $CaseDir"
}

Set-Content -LiteralPath $summaryPath -Value @(
    "CPU54 single-instruction MARS-style check",
    "CaseDir: $CaseDir",
    "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    ""
) -Encoding UTF8

$passed = 0
foreach ($case in $cases) {
    $resultPath = $case.FullName -replace '\.hex\.txt$', '.result.txt'
    if (!(Test-Path -LiteralPath $resultPath)) {
        throw "Missing result file for $($case.Name)"
    }

    Write-Host "[RUN] $($case.Name)"
    $caseLog = Join-Path $logDir ($case.Name -replace '[^A-Za-z0-9_.-]', '_' -replace '\.hex\.txt$', '.log')
    powershell -NoProfile -ExecutionPolicy Bypass -File "verify\run_hex_result_check.ps1" `
        -HexPath $case.FullName `
        -ExpectedPath $resultPath *> $caseLog
    if ($LASTEXITCODE -ne 0) {
        throw "Failed $($case.Name); see $caseLog"
    }

    $lineCount = (Get-Content -LiteralPath $resultPath).Count
    Add-Content -LiteralPath $summaryPath -Value ("PASS {0} ({1} lines)" -f $case.Name, $lineCount) -Encoding UTF8
    Write-Host "[PASS] $($case.Name)"
    $passed++
}

Add-Content -LiteralPath $summaryPath -Value @(
    "",
    "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "ALL_HEX_CASES_PASSED $passed"
) -Encoding UTF8

Write-Host "ALL_HEX_CASES_PASSED $passed"
Write-Host "summary: $summaryPath"

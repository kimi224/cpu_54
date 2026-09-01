$ErrorActionPreference = "Stop"

$vivado = "C:\Xilinx\Vivado\2016.2\bin\vivado.bat"
$targets = @(
    @{ MHz = 50; Period = "20.000" },
    @{ MHz = 40; Period = "25.000" },
    @{ MHz = 30; Period = "33.333" },
    @{ MHz = 20; Period = "50.000" },
    @{ MHz = 10; Period = "100.000" }
)

foreach ($target in $targets) {
    $env:CPU54_PERIOD_NS = $target.Period
    Write-Host "=== Trying $($target.MHz) MHz, period $($target.Period) ns ==="
    & $vivado -mode batch -source "verify\run_postsim_timing.tcl"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Vivado failed at $($target.MHz) MHz"
        continue
    }

    $suffix = "$($target.MHz)MHz"
    Copy-Item -Force "timing_report.txt" "timing_report_$suffix.txt"
    if (Test-Path "timing_paths.txt") {
        Copy-Item -Force "timing_paths.txt" "timing_paths_$suffix.txt"
    }
    if (Test-Path "utilization_report.txt") {
        Copy-Item -Force "utilization_report.txt" "utilization_report_$suffix.txt"
    }

    $timingText = Get-Content "timing_report.txt" -Raw
    if ($timingText -match "All user specified timing constraints are met") {
        Write-Host "Timing passed at $($target.MHz) MHz"
        exit 0
    }

    Write-Host "Timing failed at $($target.MHz) MHz, trying next target"
}

Write-Host "Timing did not pass at any target"
exit 1

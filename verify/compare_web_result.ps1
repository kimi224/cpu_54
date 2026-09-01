$oursPath = "_246tb_ex10_result.txt"
$stdPath = "materials\cpu54_frontsim\_246tb_ex10_result.txt"

$ours = Get-Content $oursPath
$std = Get-Content $stdPath

if ($ours.Count -ne $std.Count) {
    "line count mismatch ours $($ours.Count) std $($std.Count)"
    exit 1
}

for ($i = 0; $i -lt $std.Count; $i++) {
    if ($ours[$i] -ne $std[$i]) {
        "mismatch line $($i + 1)"
        "ours: $($ours[$i])"
        "std : $($std[$i])"
        exit 1
    }
}

"web result matched $($std.Count) lines OK"

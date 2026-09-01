param(
    [Parameter(Mandatory = $true)][string]$HexPath,
    [Parameter(Mandatory = $true)][string]$CoePath,
    [string]$MifPath
)

$ErrorActionPreference = "Stop"

$words = Get-Content -LiteralPath $HexPath |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -match '^[0-9a-fA-F]{8}$' } |
    ForEach-Object { $_.ToLowerInvariant() }

if ($words.Count -eq 0) {
    throw "No 32-bit hex words found in $HexPath"
}

$coeLines = @(
    "memory_initialization_radix = 16;",
    "memory_initialization_vector = "
)

for ($i = 0; $i -lt $words.Count; $i++) {
    if ($i -eq $words.Count - 1) {
        $coeLines += "$($words[$i]);"
    } else {
        $coeLines += "$($words[$i]),"
    }
}

Set-Content -LiteralPath $CoePath -Value $coeLines -Encoding ASCII

if ($MifPath) {
    $mifWords = $words | ForEach-Object {
        [Convert]::ToString([Convert]::ToUInt32($_, 16), 2).PadLeft(32, "0")
    }
    Set-Content -LiteralPath $MifPath -Value $mifWords -Encoding ASCII
}

Write-Host "converted $($words.Count) words"

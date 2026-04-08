$enc = New-Object System.Text.UTF8Encoding($false)
$bad = [string][char]0x00e2 + [string][char]0x20ac + [string][char]0x2122
$files = @(
    'C:\Users\oneil\Desktop\paddle\player_ids.json',
    'C:\Users\oneil\Desktop\paddle\player_history.json',
    'C:\Users\oneil\Desktop\paddle\sw_data.json',
    'C:\Users\oneil\Desktop\paddle\top_data.json',
    'C:\Users\oneil\Desktop\paddle\match_data.json',
    'C:\Users\oneil\Desktop\paddle\top_match_data.json',
    'C:\Users\oneil\Desktop\paddle\data.json'
)
foreach ($f in $files) {
    if (-not (Test-Path $f)) { Write-Host "SKIP (not found): $f"; continue }
    $raw     = [System.IO.File]::ReadAllText($f, $enc)
    $count   = ([regex]::Matches($raw, [regex]::Escape($bad))).Count
    $cleaned = $raw -replace [regex]::Escape($bad), "'"
    [System.IO.File]::WriteAllText($f, $cleaned, $enc)
    Write-Host "Fixed $f ($count replacements)"
}
Write-Host "Done."

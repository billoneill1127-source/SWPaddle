$data = Get-Content C:\Users\oneil\Desktop\paddle\player_history.json -Raw | ConvertFrom-Json
$bill = $data | Where-Object { $_.name -like "*Neill*" }
$cutoff = [datetime]'2025-09-01'
$recent = $bill.history | Where-Object {
    [datetime]::ParseExact($_.date, 'MM/dd/yy', $null) -ge $cutoff
}
Write-Host "Bill O'Neill since Sept 2025: $($recent.Count) matches"
$recent | Group-Object division | Sort-Object Name | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) matches"
}
Write-Host ""
$recent | Sort-Object { [datetime]::ParseExact($_.date, 'MM/dd/yy', $null) } | ForEach-Object {
    Write-Host "$($_.date)  $($_.division)  L$($_.line)  $($_.result)  $($_.scores)"
}

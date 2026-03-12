[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$url = 'https://aptachicago.tenniscores.com/?mod=nndz-SkhmOW1PQ3V4Zz09'
Write-Host "Fetching..."
$wc = New-Object Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$html = $wc.DownloadString($url)
Write-Host "Got $($html.Length) bytes"

# Parse loc_switcher
$locSection = [regex]::Match($html, 'id="loc_switcher"[^>]*>(.*?)</select>', [System.Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value
$locations = @{}
foreach ($m in [regex]::Matches($locSection, '<option value="(\d+)">([^<]+)')) {
    $id = $m.Groups[1].Value; $name = $m.Groups[2].Value.Trim()
    if ($id -ne "0" -and $name -ne "BYE") { $locations[$id] = $name }
}
Write-Host "Locations: $($locations.Count)"

# Parse div_switcher
$divSection = [regex]::Match($html, 'id="div_switcher"[^>]*>(.*?)</select>', [System.Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value
$divisions = @{}
foreach ($m in [regex]::Matches($divSection, '<option value="(\d+)">([^<]+)')) {
    $id = $m.Groups[1].Value; $name = $m.Groups[2].Value.Trim()
    if ($id -ne "0") { $divisions[$id] = $name }
}
Write-Host "Divisions: $($divisions.Count)"

# Parse team_switcher: <option value="219803">1 Glen Ellyn - 1
$teamSection = [regex]::Match($html, 'id="team_switcher"[^>]*>(.*?)</select>', [System.Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value
$teams = @{}
foreach ($m in [regex]::Matches($teamSection, '<option value="(\d+)">([^<]+)')) {
    $id = $m.Groups[1].Value; $name = $m.Groups[2].Value.Trim()
    if ($id -ne "0") { $teams[$id] = $name }
}
Write-Host "Teams: $($teams.Count)"

# Parse player rows — each row spans 3 lines:
# <tr class="teams divers locs team_X diver_D1 diver_D2 loc_L"><td>First</td><td><a>Last</a></td><td>Start</td>
# <td>Diff</td>
# <td class="ratings_rate">Current</td></tr>
$rowPattern = '<tr class="([^"]*)">\s*<td>([^<]*)</td>\s*<td>(?:<a[^>]*>)?([^<]*)(?:</a>)?</td>\s*<td>([^<]*)</td>\s*<td>([^<]*)</td>\s*<td[^>]*>([^<]*)</td>\s*</tr>'
$rows = [regex]::Matches($html, $rowPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
Write-Host "Player rows: $($rows.Count)"

$playersByLoc = @{}
foreach ($r in $rows) {
    $classes = $r.Groups[1].Value
    $first   = [System.Net.WebUtility]::HtmlDecode($r.Groups[2].Value.Trim())
    $last    = [System.Net.WebUtility]::HtmlDecode($r.Groups[3].Value.Trim())
    $start   = $r.Groups[4].Value.Trim()
    $diff    = $r.Groups[5].Value.Trim()
    $curr    = $r.Groups[6].Value.Trim()

    # Extract loc id
    $locMatch = [regex]::Match($classes, '\bloc_(\d+)\b')
    if (-not $locMatch.Success) { continue }
    $locId = $locMatch.Groups[1].Value

    # Extract all diver_ ids and map to names
    $diverMatches = [regex]::Matches($classes, '\bdiver_(\d+)\b')
    $divNames = @()
    foreach ($dm in $diverMatches) {
        $did = $dm.Groups[1].Value
        if ($divisions.ContainsKey($did)) { $divNames += $divisions[$did] }
    }
    $divisionName = if ($divNames.Count -gt 0) { $divNames[0] } else { "" }

    # Extract all team_ ids, map to names, sort by leading number
    $teamMatches = [regex]::Matches($classes, '\bteam_(\d+)\b')
    $teamNames = @()
    foreach ($tm in $teamMatches) {
        $tid = $tm.Groups[1].Value
        if ($teams.ContainsKey($tid)) { $teamNames += $teams[$tid] }
    }
    # Sort by the leading integer in each team name (e.g. "3 Evanston - 3" -> 3)
    $teamNames = $teamNames | Sort-Object { [int]([regex]::Match($_, '^\d+').Value) }
    # Skip players with no team (inactive)
    if ($teamNames.Count -eq 0) { continue }

    $s = [double]0; $d = [double]0; $c = [double]0
    [double]::TryParse($start, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$s) | Out-Null
    [double]::TryParse($diff,  [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d) | Out-Null
    [double]::TryParse($curr,  [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$c) | Out-Null

    if (-not $playersByLoc.ContainsKey($locId)) { $playersByLoc[$locId] = [System.Collections.ArrayList]@() }
    $playersByLoc[$locId].Add([PSCustomObject]@{
        firstName     = $first
        lastName      = $last
        startRating   = $s
        diff          = $d
        currentRating = $c
        division      = $divisionName
        teamNames     = $teamNames
    }) | Out-Null
}

$output = [System.Collections.ArrayList]@()
foreach ($locId in ($locations.Keys | Sort-Object { [int]$_ })) {
    $players = if ($playersByLoc.ContainsKey($locId)) { $playersByLoc[$locId] } else { @() }
    $output.Add([PSCustomObject]@{
        id = $locId; name = $locations[$locId]; players = @($players)
    }) | Out-Null
}

$json = $output | ConvertTo-Json -Depth 5 -Compress
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("C:\Users\oneil\Desktop\paddle\data.json", $json, $enc)
Write-Host "Done - $($output.Count) locations"
if ($output.Count -gt 0) {
    $first = $output[0]; $p = $first.players[0]
    Write-Host "Sample: $($first.name) - $($first.players.Count) players"
    Write-Host "  Top player: $($p.firstName) $($p.lastName) | teams=$($p.teamNames -join ', ') | division=$($p.division) | current=$($p.currentRating)"
}

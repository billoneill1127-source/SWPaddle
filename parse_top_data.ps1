[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$BASE     = 'https://aptachicago.tenniscores.com'
$TEAM_MOD = 'nndz-TjJiOWtORzkwTlJFb0NVU1NzOD0%3D'

# Fetch main page HTML with UTF8 encoding
Write-Host "Fetching main page..."
$wc = New-Object Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$mainHtml = $wc.DownloadString("$BASE/?mod=nndz-SkhmOW1PQ3V4Zz09")

# Extract Top series (Chicago 1-6) team token -> display name
# Team names end with " - N" where N is 1-6 (no SW suffix)
$topTeams = @{}
$topTeamOrder = [System.Collections.ArrayList]@()
foreach ($m in [regex]::Matches($mainHtml, 'team=(nndz-[^"]+)"[^>]*>([^<]+)<')) {
    $token = $m.Groups[1].Value.Trim()
    $name  = $m.Groups[2].Value.Trim()
    $numM  = [regex]::Match($name, '-\s*([1-6])\s*$')
    if ($numM.Success -and $name -notlike '* SW*') {
        if (-not $topTeams.Contains($token)) {
            $topTeams[$token] = $name
            $topTeamOrder.Add($token) | Out-Null
        }
    }
}
Write-Host "Top series teams found: $($topTeams.Count)"

# Fetch each team page and parse
$divStandings = @{}
$teamRosters  = @{}
$lagrangeIds  = [System.Collections.Generic.Dictionary[string,PSCustomObject]]::new()

# Player pattern — Group 1: playerID, Group 2: name, Group 3: rating, Group 4: wins, Group 5: losses
$playerPat = '<a class="lightbox-auto iframe link"[^>]*player\.php[^"]*?[?&]p=(nndz-[^"&]+)[^>]*>([^<]+)</a>[^<]*(?:\(C\))?\s*</div></td><td>\s*([\-\d.]+)\s*</td>\s*<td[^>]*><span class="md-font-gray">(\d+)</span></td>\s*<td[^>]*><span class="md-font-gray">(\d+)</span></td>'

$i = 0
foreach ($token in $topTeamOrder) {
    $i++
    $teamName = $topTeams[$token]
    Write-Host "[$i/$($topTeams.Count)] $teamName"

    $url = "$BASE/?mod=$TEAM_MOD&team=$token"
    try {
        $html = $wc.DownloadString($url)

        # Derive division name: "Chicago N"
        $numM    = [regex]::Match($teamName, '-\s*([1-6])\s*$')
        $divName = if ($numM.Success) { "Chicago " + $numM.Groups[1].Value } else { "Unknown" }

        # Parse standings table (once per division)
        if (-not $divStandings.ContainsKey($divName)) {
            $standSection = [regex]::Match($html,
                '<table class="standings-table2 division_standings"[^>]*>(.*?)</table>',
                [System.Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value
            $standRows = [regex]::Matches($standSection,
                '<tr class="(?:odd|even)">\s*<td class="team2"><a href="[^"]*team=([^"]+)"[^>]*>([^<]+)</a></td>\s*<td class="pts2">(\d+)</td>')
            $list = [System.Collections.ArrayList]@()
            foreach ($sr in $standRows) {
                $list.Add(@{
                    token = $sr.Groups[1].Value.Trim()
                    name  = $sr.Groups[2].Value.Trim()
                    pts   = [int]$sr.Groups[3].Value
                }) | Out-Null
            }
            $divStandings[$divName] = $list
        }

        # Parse player roster: playerID, name, rating, wins, losses
        $playerRows = [regex]::Matches($html, $playerPat, [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $players = [System.Collections.ArrayList]@()
        foreach ($pr in $playerRows) {
            $plrId    = $pr.Groups[1].Value.Trim()
            $pName  = [System.Net.WebUtility]::HtmlDecode($pr.Groups[2].Value.Trim()) -replace '\s+', ' ' -replace "\u00e2\u20ac\u2122", "'"
            $rating = 0.0; [double]::TryParse($pr.Groups[3].Value.Trim(),
                [System.Globalization.NumberStyles]::Any,
                [System.Globalization.CultureInfo]::InvariantCulture, [ref]$rating) | Out-Null
            $wins   = [int]$pr.Groups[4].Value
            $losses = [int]$pr.Groups[5].Value
            $players.Add([PSCustomObject]@{
                name   = $pName
                rating = $rating
                wins   = $wins
                losses = $losses
                games  = $wins + $losses
            }) | Out-Null

            # Harvest player ID for LaGrange CC rosters
            if ($teamName -like '*LaGrange CC*' -and $plrId -and -not $lagrangeIds.ContainsKey($plrId)) {
                $lagrangeIds[$plrId] = [PSCustomObject]@{
                    name     = $pName
                    team     = $teamName
                    playerID = $plrId
                }
            }
        }

        $teamRosters[$token] = @($players)
        Write-Host "  -> $($players.Count) players"
    }
    catch {
        Write-Host "  ERROR: $($_.Exception.Message)"
        $teamRosters[$token] = @()
    }
}

# Build final JSON: divisions sorted by number, teams in standings order
$output = [System.Collections.ArrayList]@()
foreach ($divName in ($divStandings.Keys | Sort-Object { [int]([regex]::Match($_, '\d+').Value) })) {
    $divTeams = [System.Collections.ArrayList]@()
    $place = 1
    foreach ($standing in $divStandings[$divName]) {
        if ($standing.name -like '*BYE*') { continue }
        $token   = $standing.token
        $players = if ($teamRosters.ContainsKey($token)) { $teamRosters[$token] } else { @() }

        $totalGames   = ($players | Measure-Object -Property games  -Sum).Sum
        $totalGames   = if ($null -eq $totalGames) { 0 } else { [int]$totalGames }
        $avgPTI       = if ($players.Count -gt 0) { [Math]::Round(($players | Measure-Object -Property rating -Average).Average, 2) } else { 0 }
        $weightedSum  = 0.0
        foreach ($p in $players) { $weightedSum += $p.games * $p.rating }
        $avgPTIPerGame = if ($totalGames -gt 0) { [Math]::Round($weightedSum / $totalGames, 2) } else { 0 }

        $divTeams.Add([PSCustomObject]@{
            name          = $standing.name
            place         = $place
            pts           = $standing.pts
            gamesRoster   = $totalGames
            avgPTI        = $avgPTI
            avgPTIPerGame = $avgPTIPerGame
            players       = $players
        }) | Out-Null
        $place++
    }

    $output.Add([PSCustomObject]@{
        division = $divName
        teams    = @($divTeams)
    }) | Out-Null
}

$json = $output | ConvertTo-Json -Depth 6 -Compress
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("C:\Users\oneil\Desktop\paddle\top_data.json", $json, $enc)

# Merge LaGrange CC player IDs with any entries already written by another script run
$idFile = "C:\Users\oneil\Desktop\paddle\player_ids.json"
$merged = [System.Collections.Generic.Dictionary[string,PSCustomObject]]::new()
if (Test-Path $idFile) {
    try {
        $existing = [System.IO.File]::ReadAllText($idFile, $enc) | ConvertFrom-Json
        foreach ($e in $existing) { $merged[$e.playerID] = $e }
    } catch { Write-Host "  WARN: could not read existing player_ids.json" }
}
foreach ($plrId in $lagrangeIds.Keys) { $merged[$plrId] = $lagrangeIds[$plrId] }
$idArr = @($merged.Values | Sort-Object name)
[System.IO.File]::WriteAllText($idFile, ($idArr | ConvertTo-Json -Depth 3 -Compress), $enc)
Write-Host "player_ids.json: $($lagrangeIds.Count) LaGrange CC Top players ($($merged.Count) total)"

Write-Host ""
Write-Host "Done! $($output.Count) Top divisions written to top_data.json"
if ($output.Count -gt 0) {
    $d = $output[0]; $t = $d.teams[0]
    Write-Host "Sample: $($d.division) | 1st: $($t.name) place=$($t.place) pts=$($t.pts) games=$($t.gamesRoster) avgPTI=$($t.avgPTI)"
}

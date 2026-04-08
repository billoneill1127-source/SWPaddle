[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$BASE     = 'https://aptachicago.tenniscores.com'
$TEAM_MOD = 'nndz-TjJiOWtORzkwTlJFb0NVU1NzOD0%3D'

# Fetch main page HTML with UTF8 encoding to handle special characters (apostrophes, etc.)
Write-Host "Fetching main page..."
$url0 = 'https://aptachicago.tenniscores.com/?mod=nndz-SkhmOW1PQ3V4Zz09'
$wc = New-Object Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$mainHtml = $wc.DownloadString($url0)

# Extract SW team token → display name from div_list_teams links
$swTeamMatches = [regex]::Matches($mainHtml, 'team=(nndz-[^"]+)"[^>]*>([^<]+ SW\b[^<]*)<')
$swTeams = @{}
$swTeamOrder = [System.Collections.ArrayList]@()
foreach ($m in $swTeamMatches) {
    $token = $m.Groups[1].Value.Trim()
    $name  = $m.Groups[2].Value.Trim()
    if (-not $swTeams.Contains($token)) {
        $swTeams[$token] = $name
        $swTeamOrder.Add($token) | Out-Null
    }
}
Write-Host "SW teams found: $($swTeams.Count)"

# Fetch each SW team page and parse
$divStandings = @{}   # divName -> ordered list of {token, name, pts}
$teamRosters  = @{}   # token -> list of {name, rating, wins, losses, games}
$lagrangeIds  = [System.Collections.Generic.Dictionary[string,PSCustomObject]]::new()

# Player pattern — Group 1: playerID, Group 2: name, Group 3: rating, Group 4: wins, Group 5: losses
$playerPat = '<a class="lightbox-auto iframe link"[^>]*player\.php[^"]*?[?&]p=(nndz-[^"&]+)[^>]*>([^<]+)</a>[^<]*(?:\(C\))?\s*</div></td><td>\s*([\-\d.]+)\s*</td>\s*<td[^>]*><span class="md-font-gray">(\d+)</span></td>\s*<td[^>]*><span class="md-font-gray">(\d+)</span></td>'

$i = 0
foreach ($token in $swTeamOrder) {
    $i++
    $teamName = $swTeams[$token]
    Write-Host "[$i/$($swTeams.Count)] $teamName"

    $url = "$BASE/?mod=$TEAM_MOD&team=$token"
    try {
        $html = $wc.DownloadString($url)

        # Derive division name from team name (e.g. "Glen Ellyn - 7 SW" → "Chicago 7 SW")
        $divMatch = [regex]::Match($teamName, '(\d+ SW)')
        $divName  = if ($divMatch.Success) { "Chicago " + $divMatch.Groups[1].Value } else { "Unknown" }

        # Parse standings table (only once per division)
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

# Build final JSON: divisions sorted, teams in standings order
$output = [System.Collections.ArrayList]@()
foreach ($divName in ($divStandings.Keys | Sort-Object { [int]([regex]::Match($_, '\d+').Value) })) {
    $divTeams = [System.Collections.ArrayList]@()
    $place = 1
    foreach ($standing in $divStandings[$divName]) {
        if ($standing.name -like '*BYE*') { continue }
        $token   = $standing.token
        $players = if ($teamRosters.ContainsKey($token)) { $teamRosters[$token] } else { @() }

        $totalGames  = ($players | Measure-Object -Property games  -Sum).Sum
        $totalGames  = if ($null -eq $totalGames) { 0 } else { [int]$totalGames }
        $avgPTI      = if ($players.Count -gt 0) { [Math]::Round(($players | Measure-Object -Property rating -Average).Average, 2) } else { 0 }
        $weightedSum = 0.0
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
[System.IO.File]::WriteAllText("C:\Users\oneil\Desktop\paddle\sw_data.json", $json, $enc)

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
Write-Host "player_ids.json: $($lagrangeIds.Count) LaGrange CC SW players ($($merged.Count) total)"

Write-Host ""
Write-Host "Done! $($output.Count) SW divisions written to sw_data.json"
if ($output.Count -gt 0) {
    $d = $output[0]; $t = $d.teams[0]
    Write-Host "Sample: $($d.division) | 1st: $($t.name) place=$($t.place) pts=$($t.pts) games=$($t.gamesRoster) avgPTI=$($t.avgPTI) avgPTI/Game=$($t.avgPTIPerGame)"
    if ($t.players.Count -gt 0) {
        $p = $t.players[0]
        Write-Host "  Player: $($p.name) rating=$($p.rating) W=$($p.wins) L=$($p.losses)"
    }
}

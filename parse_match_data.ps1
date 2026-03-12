[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$BASE     = 'https://aptachicago.tenniscores.com'
$TEAM_MOD = 'nndz-TjJiOWtORzkwTlJFb0NVU1NzOD0%3D'

$wc = New-Object Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8

# --- Step 1: Fetch main page and get all SW team tokens ---
Write-Host "Fetching main page..."
$mainHtml = $wc.DownloadString("$BASE/?mod=nndz-SkhmOW1PQ3V4Zz09")

$swTeams = @{}
$swTeamOrder = [System.Collections.ArrayList]@()
foreach ($m in [regex]::Matches($mainHtml, 'team=(nndz-[^"]+)"[^>]*>([^<]+ SW\b[^<]*)<')) {
    $tok  = $m.Groups[1].Value.Trim()
    $name = $m.Groups[2].Value.Trim()
    if (-not $swTeams.Contains($tok)) {
        $swTeams[$tok] = $name
        $swTeamOrder.Add($tok) | Out-Null
    }
}
Write-Host "SW teams: $($swTeams.Count)"

# --- Step 2: For each SW team, collect THIS TEAM'S match tokens from their own standings row ---
$allMatchTokens  = @{}   # matchToken -> @{token; teamsByToken}
$teamToMatches   = @{}   # teamToken  -> [matchToken, ...]

$i = 0
foreach ($teamToken in $swTeamOrder) {
    $i++
    $teamName = $swTeams[$teamToken]
    if ($i % 20 -eq 0) { Write-Host "  [$i/$($swTeamOrder.Count)] Scanning $teamName" }

    try {
        $teamHtml = $wc.DownloadString("$BASE/?mod=$TEAM_MOD&team=$teamToken")

        # Find all TR blocks; look for the one whose team2 link contains this team's token
        $trBlocks = [regex]::Matches($teamHtml, '<tr[^>]*>(.*?)</tr>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $myToks = [System.Collections.ArrayList]@()
        foreach ($tr in $trBlocks) {
            $content = $tr.Groups[1].Value
            # Check if this row's team2 link points to our team
            if ($content -notlike "*team=$teamToken*") { continue }
            # Extract match tokens from cells in this row
            foreach ($mt in [regex]::Matches($content, 'print_match\.php\?sch=(nndz-[^&"]+)')) {
                $tok = $mt.Groups[1].Value.Trim()
                $allMatchTokens[$tok] = $true
                $myToks.Add($tok) | Out-Null
            }
            break  # found this team's row, done
        }
        $teamToMatches[$teamToken] = @($myToks)
    }
    catch {
        $teamToMatches[$teamToken] = @()
        if ($i % 20 -eq 0) { Write-Host "    ERROR: $($_.Exception.Message)" }
    }
}
Write-Host "Unique match tokens collected: $($allMatchTokens.Count)"

# --- Step 3: Fetch each unique match detail page and parse ---
$matchList = [System.Collections.ArrayList]@()
$j = 0
$total = $allMatchTokens.Count

foreach ($matchTok in $allMatchTokens.Keys) {
    $j++
    if ($j % 50 -eq 0) { Write-Host "  [$j/$total] Fetching match details..." }

    try {
        $mHtml = $wc.DownloadString("$BASE/print_match.php?sch=$matchTok&print&")

        # Parse header: "TEAM1  @ TEAM2:   score1  -  score2"
        $hdr = [regex]::Match($mHtml,
            'class="datelocheader">([^<@]+@[^:<]+):\s*(?:&nbsp;\s*)*<span[^>]*>(\d+)</span>[^<]*(?:<[^>]*>[^<]*</[^>]*>)*\s*-\s*<span[^>]*>(\d+)</span>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if (-not $hdr.Success) { continue }

        $raw   = $hdr.Groups[1].Value
        $atIdx = $raw.LastIndexOf(' @ ')
        if ($atIdx -lt 0) { continue }
        $team1   = [System.Net.WebUtility]::HtmlDecode($raw.Substring(0, $atIdx).Trim())
        $team2   = [System.Net.WebUtility]::HtmlDecode($raw.Substring($atIdx + 3).Trim())
        $score1  = [int]$hdr.Groups[2].Value
        $score2  = [int]$hdr.Groups[3].Value

        # Parse date  (e.g. "February 11, 2026")
        $dateM = [regex]::Match($mHtml, '([A-Z][a-z]+ \d{1,2}, \d{4})')
        $date  = if ($dateM.Success) { $dateM.Groups[1].Value } else { '' }

        # Parse each line: match <tr class="tr_line_desc"> (row1) + next <tr> (row2)
        $lineBlocks = [regex]::Matches($mHtml,
            '<tr class="tr_line_desc">(.*?)</tr>\s*<tr>(.*?)</tr>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $lines = [System.Collections.ArrayList]@()
        foreach ($lb in $lineBlocks) {
            $row1 = $lb.Groups[1].Value
            $row2 = $lb.Groups[2].Value

            # Line number
            $lineNum = [regex]::Match($row1, 'Line (\d+)')
            if (-not $lineNum.Success) { continue }

            # Winner: row with check_green.png won
            $row1Wins = ($row1 -like '*check_green.png*')

            # Parse player names from <a> tags in card_names td
            # Pattern: <a href="...">Name</a> PTI
            function Get-Pair($html) {
                $names = [System.Collections.ArrayList]@()
                $ptis  = [System.Collections.ArrayList]@()
                $cardM = [regex]::Match($html, 'class="form1 card_names"[^>]*>(.*?)</td>',
                    [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if (-not $cardM.Success) { return @{n=@('',''); p=@(0.0,0.0)} }
                $cardContent = $cardM.Groups[1].Value
                foreach ($pm in [regex]::Matches($cardContent, '>([^<]{2,50}?)</a>\s*([\d.]+)?')) {
                    $n = [System.Net.WebUtility]::HtmlDecode($pm.Groups[1].Value.Trim()) -replace '\s+', ' ' -replace '\(C\)', '' -replace '^\s+|\s+$', ''
                    if ($n.Length -lt 2 -or $n -match '^\d') { continue }
                    $p = 0.0
                    [double]::TryParse($pm.Groups[2].Value.Trim(),
                        [System.Globalization.NumberStyles]::Any,
                        [System.Globalization.CultureInfo]::InvariantCulture, [ref]$p) | Out-Null
                    $names.Add($n)  | Out-Null
                    $ptis.Add($p)   | Out-Null
                }
                # Pad to 2 elements
                while ($names.Count -lt 2) { $names.Add('') | Out-Null; $ptis.Add(0.0) | Out-Null }
                return @{n=@($names[0],$names[1]); p=@($ptis[0],$ptis[1])}
            }

            $p1 = Get-Pair $row1
            $p2 = Get-Pair $row2

            # Parse set scores: pts2 cells with numeric content
            function Get-Scores($html) {
                $scores = [System.Collections.ArrayList]@()
                foreach ($sm in [regex]::Matches($html, '<td[^>]*class="[^"]*pts2[^"]*"[^>]*>(\d+)</td>')) {
                    $scores.Add([int]$sm.Groups[1].Value) | Out-Null
                }
                return @($scores)
            }

            $s1 = Get-Scores $row1
            $s2 = Get-Scores $row2

            $lines.Add([PSCustomObject]@{
                line    = [int]$lineNum.Groups[1].Value
                pair1   = $p1.n
                pti1    = $p1.p
                pair2   = $p2.n
                pti2    = $p2.p
                scores1 = $s1
                scores2 = $s2
                winner  = if ($row1Wins) { 1 } else { 2 }
            }) | Out-Null
        }

        if ($lines.Count -gt 0) {
            $matchList.Add([PSCustomObject]@{
                token  = $matchTok
                date   = $date
                team1  = $team1
                team2  = $team2
                score1 = $score1
                score2 = $score2
                lines  = @($lines)
            }) | Out-Null
        }
    }
    catch {
        # Skip failed match fetches silently
    }
}

Write-Host ""
Write-Host "Parsed $($matchList.Count) matches"

$json = $matchList | ConvertTo-Json -Depth 7 -Compress
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("C:\Users\oneil\Desktop\paddle\match_data.json", $json, $enc)
Write-Host "Written to match_data.json"
if ($matchList.Count -gt 0) {
    $m = $matchList[0]
    Write-Host "Sample: $($m.team1) @ $($m.team2) = $($m.score1)-$($m.score2) on $($m.date)"
    if ($m.lines.Count -gt 0) {
        $l = $m.lines[0]
        Write-Host "  Line $($l.line): $($l.pair1[0])/$($l.pair1[1]) vs $($l.pair2[0])/$($l.pair2[1]) winner=$($l.winner)"
    }
}

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$BASE     = 'https://aptachicago.tenniscores.com'
$TEAM_MOD = 'nndz-TjJiOWtORzkwTlJFb0NVU1NzOD0%3D'

$wc = New-Object Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8

# --- Step 1: Fetch main page and get all Chicago 1-6 team tokens ---
Write-Host "Fetching main page..."
$mainHtml = $wc.DownloadString("$BASE/?mod=nndz-SkhmOW1PQ3V4Zz09")

$topTeams = @{}
$topTeamOrder = [System.Collections.ArrayList]@()
foreach ($m in [regex]::Matches($mainHtml, 'team=(nndz-[^"]+)"[^>]*>([^<]+)<')) {
    $tok  = $m.Groups[1].Value.Trim()
    $name = $m.Groups[2].Value.Trim()
    $numM = [regex]::Match($name, '-\s*([1-6])\s*$')
    if ($numM.Success -and $name -notlike '* SW*') {
        if (-not $topTeams.Contains($tok)) {
            $topTeams[$tok] = $name
            $topTeamOrder.Add($tok) | Out-Null
        }
    }
}
Write-Host "Top series teams: $($topTeams.Count)"

# --- Step 2: For each team, collect match tokens from their own standings row ---
$allMatchTokens = @{}
$teamToMatches  = @{}

$i = 0
foreach ($teamToken in $topTeamOrder) {
    $i++
    $teamName = $topTeams[$teamToken]
    if ($i % 10 -eq 0) { Write-Host "  [$i/$($topTeamOrder.Count)] Scanning $teamName" }

    try {
        $teamHtml = $wc.DownloadString("$BASE/?mod=$TEAM_MOD&team=$teamToken")

        $trBlocks = [regex]::Matches($teamHtml, '<tr[^>]*>(.*?)</tr>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $myToks = [System.Collections.ArrayList]@()
        foreach ($tr in $trBlocks) {
            $content = $tr.Groups[1].Value
            if ($content -notlike "*team=$teamToken*") { continue }
            foreach ($mt in [regex]::Matches($content, 'print_match\.php\?sch=(nndz-[^&"]+)')) {
                $tok = $mt.Groups[1].Value.Trim()
                $allMatchTokens[$tok] = $true
                $myToks.Add($tok) | Out-Null
            }
            break
        }
        $teamToMatches[$teamToken] = @($myToks)
    }
    catch {
        $teamToMatches[$teamToken] = @()
    }
}
Write-Host "Unique match tokens collected: $($allMatchTokens.Count)"

# --- Step 3: Fetch each match detail page and parse ---
$matchList = [System.Collections.ArrayList]@()
$j = 0
$total = $allMatchTokens.Count

foreach ($matchTok in $allMatchTokens.Keys) {
    $j++
    if ($j % 50 -eq 0) { Write-Host "  [$j/$total] Fetching match details..." }

    try {
        $mHtml = $wc.DownloadString("$BASE/print_match.php?sch=$matchTok&print&")

        $hdr = [regex]::Match($mHtml,
            'class="datelocheader">([^<@]+@[^:<]+):\s*(?:&nbsp;\s*)*<span[^>]*>(\d+)</span>[^<]*(?:<[^>]*>[^<]*</[^>]*>)*\s*-\s*<span[^>]*>(\d+)</span>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if (-not $hdr.Success) { continue }

        $raw   = $hdr.Groups[1].Value
        $atIdx = $raw.LastIndexOf(' @ ')
        if ($atIdx -lt 0) { continue }
        $team1  = [System.Net.WebUtility]::HtmlDecode($raw.Substring(0, $atIdx).Trim())
        $team2  = [System.Net.WebUtility]::HtmlDecode($raw.Substring($atIdx + 3).Trim())
        $score1 = [int]$hdr.Groups[2].Value
        $score2 = [int]$hdr.Groups[3].Value

        $dateM = [regex]::Match($mHtml, '([A-Z][a-z]+ \d{1,2}, \d{4})')
        $date  = if ($dateM.Success) { $dateM.Groups[1].Value } else { '' }

        $lineBlocks = [regex]::Matches($mHtml,
            '<tr class="tr_line_desc">(.*?)</tr>\s*<tr>(.*?)</tr>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $lines = [System.Collections.ArrayList]@()
        foreach ($lb in $lineBlocks) {
            $row1 = $lb.Groups[1].Value
            $row2 = $lb.Groups[2].Value

            $lineNum = [regex]::Match($row1, 'Line (\d+)')
            if (-not $lineNum.Success) { continue }

            $row1Wins = ($row1 -like '*check_green.png*')

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
                while ($names.Count -lt 2) { $names.Add('') | Out-Null; $ptis.Add(0.0) | Out-Null }
                return @{n=@($names[0],$names[1]); p=@($ptis[0],$ptis[1])}
            }

            $p1 = Get-Pair $row1
            $p2 = Get-Pair $row2

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
    catch { }
}

Write-Host ""
Write-Host "Parsed $($matchList.Count) matches"

$json = $matchList | ConvertTo-Json -Depth 7 -Compress
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("C:\Users\oneil\Desktop\paddle\top_match_data.json", $json, $enc)
Write-Host "Written to top_match_data.json"

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$BASE     = 'https://aptachicago.tenniscores.com'
$HIST_MOD = 'nndz-Sm5yb2lPdTcxdFJibXc9PQ%3D%3D'
$CUTOFF   = [datetime]::ParseExact('01/01/19', 'MM/dd/yy', $null)
$enc      = New-Object System.Text.UTF8Encoding($false)
$idPath   = 'C:\Users\oneil\Desktop\paddle\player_ids.json'
$outPath  = 'C:\Users\oneil\Desktop\paddle\player_history.json'

# ── Helper: split "First Last Rating" → {name, rating} ───────────────────────
function Split-NameRating([string]$text) {
    $text = ([System.Net.WebUtility]::HtmlDecode($text) `
        -replace '<[^>]+>', '' -replace '\s+', ' ' -replace "\u00e2\u20ac\u2122", "'").Trim()
    $m = [regex]::Match($text, '^(.*?)\s+([\d.]+)\s*$')
    if ($m.Success) {
        $r = 0.0
        [double]::TryParse($m.Groups[2].Value,
            [System.Globalization.NumberStyles]::Any,
            [System.Globalization.CultureInfo]::InvariantCulture, [ref]$r) | Out-Null
        return @{ name = $m.Groups[1].Value.Trim(); rating = $r }
    }
    return @{ name = $text; rating = 0.0 }
}

# ── Load inputs ───────────────────────────────────────────────────────────────
$players = [System.IO.File]::ReadAllText($idPath, $enc) | ConvertFrom-Json
$wc      = New-Object Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8

$output = [System.Collections.ArrayList]@()
$i = 0

foreach ($player in $players) {
    $i++
    Write-Host "[$i/$($players.Count)] $($player.name)"
    $history = [System.Collections.ArrayList]@()

    try {
        $url  = "$BASE/?print&mod=$HIST_MOD&all&p=$($player.playerID)"
        $html = $wc.DownloadString($url)

        # ── Split HTML into section blocks on shader+match_type_League ────────
        $sectionParts = [regex]::Split($html,
            '(?=<div[^>]*class="[^"]*shader\b[^"]*match_type_League[^"]*")')

        foreach ($section in $sectionParts) {

            # Division name from sectioner div
            $sectionerM = [regex]::Match($section,
                '<div[^>]*class="sectioner"[^>]*>(.*?)</div>',
                [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if (-not $sectionerM.Success) { continue }
            $division = ([System.Net.WebUtility]::HtmlDecode(
                $sectionerM.Groups[1].Value.Trim())) -replace "\u00e2\u20ac\u2122", "'"

            # ── Split section into individual match chunks ─────────────────
            $matchParts = [regex]::Split($section, '(?=<div\s+id="match_\d+")')

            foreach ($matchChunk in $matchParts) {
                if ($matchChunk -notmatch 'id="match_\d+"') { continue }

                # Date ────────────────────────────────────────────────────────
                $dateM = [regex]::Match($matchChunk,
                    'style="width:\s*68px[^"]*"[^>]*>\s*([0-9/]+)\s*</div>')
                if (-not $dateM.Success) { continue }
                $dateStr = $dateM.Groups[1].Value.Trim()
                try   { $matchDate = [datetime]::ParseExact($dateStr, 'MM/dd/yy', $null) }
                catch { continue }
                if ($matchDate -lt $CUTOFF) { continue }

                # Match description (anchor text in 405px div) ────────────────
                $matchNameM = [regex]::Match($matchChunk,
                    'style="width:\s*405px[^"]*"[^>]*>.*?<a[^>]*>(.*?)</a>',
                    [System.Text.RegularExpressions.RegexOptions]::Singleline)
                $matchName = if ($matchNameM.Success) {
                    ([System.Net.WebUtility]::HtmlDecode(
                        $matchNameM.Groups[1].Value.Trim())) -replace "\u00e2\u20ac\u2122", "'"
                } else { '' }

                # Line number (20px div) ───────────────────────────────────────
                $lineM = [regex]::Match($matchChunk,
                    'style="width:\s*20px[^"]*"[^>]*>\s*(\d+)\s*</div>')
                $lineNum = if ($lineM.Success) { [int]$lineM.Groups[1].Value } else { 0 }

                # Result W/L (57px div) ───────────────────────────────────────
                $resultM = [regex]::Match($matchChunk,
                    'style="width:\s*57px[^"]*"[^>]*>\s*([WL])\s*</div>')
                $result = if ($resultM.Success) {
                    $resultM.Groups[1].Value.Trim() } else { '' }

                # Player PTI at time of match (60px div) ─────────────────────
                $ratingM = [regex]::Match($matchChunk,
                    'style="width:\s*60px[^"]*"[^>]*>\s*([\-\d.]+)\s*</div>')
                $matchRating = 0.0
                if ($ratingM.Success) {
                    [double]::TryParse($ratingM.Groups[1].Value,
                        [System.Globalization.NumberStyles]::Any,
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [ref]$matchRating) | Out-Null
                }

                # Match card ─────────────────────────────────────────────────
                $cardM = [regex]::Match($matchChunk,
                    'class="match_card[^"]*"[^>]*>(.*)',
                    [System.Text.RegularExpressions.RegexOptions]::Singleline)
                if (-not $cardM.Success) { continue }
                # Strip trailing closing-div tags (match_card close + match_ div close)
                $cardContent = $cardM.Groups[1].Value -replace '(?:\s*</div>)+\s*$', ''

                # Collect and classify every div within the card:
                #   score   → single integer (set score)
                #   player  → contains <b> (viewing player's pair)
                #   opponent → contains '/' but no <b> (opponents)
                $divMatches = [regex]::Matches($cardContent,
                    '<div[^>]*>(.*?)</div>',
                    [System.Text.RegularExpressions.RegexOptions]::Singleline)

                $rows = [System.Collections.ArrayList]@()
                foreach ($dm in $divMatches) {
                    $raw  = $dm.Groups[1].Value
                    $text = ($raw -replace '<[^>]+>', '' -replace '\s+', ' ').Trim()
                    if     ($text -match '^\d+$') {
                        $rows.Add(@{ t = 'score'; v = [int]$text }) | Out-Null
                    } elseif ($raw -match '<[bB]>') {
                        $rows.Add(@{ t = 'player'; raw = $raw; text = $text }) | Out-Null
                    } elseif ($text -match '/') {
                        $rows.Add(@{ t = 'opponent'; text = $text }) | Out-Null
                    }
                }

                # Locate player and opponent row indices
                $ra = @($rows)
                $playerIdx = -1; $opponentIdx = -1
                for ($ri = 0; $ri -lt $ra.Count; $ri++) {
                    if ($ra[$ri].t -eq 'player'   -and $playerIdx   -lt 0) { $playerIdx   = $ri }
                    if ($ra[$ri].t -eq 'opponent' -and $opponentIdx -lt 0) { $opponentIdx = $ri }
                }
                # Skip forfeits (missing either row)
                if ($playerIdx -lt 0 -or $opponentIdx -lt 0) { continue }

                # Parse player row → partner name & rating ───────────────────
                $playerText = $ra[$playerIdx].text
                $playerRaw  = $ra[$playerIdx].raw
                if ($playerText -notmatch '/') { continue }
                $playerParts   = $playerText -split ' / ', 2
                # The viewing player's name is bold in the raw HTML.
                # Determine which side of '/' carries the <b> tag.
                $rawLeft       = ($playerRaw -split '/', 2)[0]
                $viewerIsLeft  = [bool]($rawLeft -match '<[bB]>')
                $partnerParsed = if ($viewerIsLeft) { Split-NameRating $playerParts[1] } else { Split-NameRating $playerParts[0] }
                $partner       = $partnerParsed.name
                $partnerRating = $partnerParsed.rating

                # Parse opponent row ──────────────────────────────────────────
                $oppText  = $ra[$opponentIdx].text
                if ($oppText -notmatch '/') { continue }
                $oppParts = $oppText -split ' / ', 2
                $opp1 = Split-NameRating $oppParts[0]
                $opp2 = Split-NameRating $oppParts[1]
                if (-not $opp1.name -or -not $opp2.name) { continue }

                # Collect set scores (consecutive score rows after each pair row)
                $playerScores   = @()
                $opponentScores = @()
                for ($ri = $playerIdx + 1;   $ri -lt $ra.Count; $ri++) {
                    if ($ra[$ri].t -eq 'score') { $playerScores   += $ra[$ri].v } else { break }
                }
                for ($ri = $opponentIdx + 1; $ri -lt $ra.Count; $ri++) {
                    if ($ra[$ri].t -eq 'score') { $opponentScores += $ra[$ri].v } else { break }
                }

                # Build "playerScore-opponentScore, ..." string
                $scoreParts = @()
                $sets = [Math]::Min($playerScores.Count, $opponentScores.Count)
                for ($s = 0; $s -lt $sets; $s++) {
                    $scoreParts += "$($playerScores[$s])-$($opponentScores[$s])"
                }
                $scoreStr = $scoreParts -join ', '

                $history.Add([PSCustomObject]@{
                    date            = $dateStr
                    division        = $division
                    match           = $matchName
                    line            = $lineNum
                    result          = $result
                    rating          = $matchRating
                    partner         = $partner
                    partnerRating   = $partnerRating
                    opponents       = @($opp1.name, $opp2.name)
                    opponentRatings = @($opp1.rating, $opp2.rating)
                    scores          = $scoreStr
                }) | Out-Null
            }
        }
    }
    catch {
        Write-Host "  ERROR: $($_.Exception.Message)"
    }

    $output.Add([PSCustomObject]@{
        name     = $player.name
        team     = $player.team
        playerID = $player.playerID
        history  = @($history)
    }) | Out-Null

    Write-Host "  -> $($history.Count) matches"
    Start-Sleep -Seconds 1
}

$json = $output | ConvertTo-Json -Depth 7 -Compress
[System.IO.File]::WriteAllText($outPath, $json, $enc)
Write-Host ""
Write-Host "Done! $($output.Count) players written to player_history.json"
$sample = $output | Where-Object { $_.history.Count -gt 0 } | Select-Object -First 1
if ($sample) {
    $m = $sample.history[0]
    Write-Host "Sample: $($sample.name) ($($sample.history.Count) matches)"
    Write-Host "  First entry: $($m.date) $($m.division) L$($m.line) $($m.result) partner=$($m.partner) score=$($m.scores)"
}

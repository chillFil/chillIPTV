# PowerShell script to test streams
# Usage: .\check_streams.ps1 -Urls 'url1','url2' [-OutputFile 'results.csv'] [-SegmentCount 3]

param(
    [string[]]$Urls,
    [string]$OutputFile = '',
    [int]$SegmentCount = 3
)

if (-not $Urls -or $Urls.Count -eq 0) {
    $Urls = @(
        'https://mediapolis.rai.it/relinker/relinkerServlet.htm?cont=2606803&output=7&forceUserAgent=raiplayappletv',
        'https://viamotionhsi.netplus.ch/live/eds/rai1/browser-HLS8/rai1.m3u8'
    )
}

if (-not $OutputFile -or [string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = "stream_test_results_{0}.csv" -f (Get-Date -Format yyyyMMdd_HHmmss)
}

# Helper: run command if available
function CommandExists($cmd) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    return $null -ne $c
}

# Clean results
if (Test-Path $OutputFile) { Remove-Item $OutputFile -Force }
"URL,HTTPStatus,HasMaster,TopBandwidth,TopResolution,ProbeOK,ProbeCodec,ProbeBitrate,ProbeWidth,ProbeHeight,FFmpegPlayOK,FFmpegErrors,AvgSegmentSizeBytes,AvgSegmentDownloadMs" | Out-File -FilePath $OutputFile

foreach ($url in $Urls) {
    Write-Output "Testing: $url"

    # HTTP HEAD (fallback to GET)
    $status = 'ERR'
    try {
        $head = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -ErrorAction Stop
        $status = $head.StatusCode
    } catch {
        try {
            $get = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            $status = $get.StatusCode
        } catch {
            $status = 'ERR'
        }
    }

    # Get manifest text
    $text = ''
    try { $text = (Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop).Content } catch { $text = '' }

    $hasMaster = $text -match '#EXT-X-STREAM-INF'
    $topBw = ''
    $topRes = ''
    $probeOK = 'SKIP'
    $probeCodec = ''
    $probeBitrate = ''
    $probeWidth = ''
    $probeHeight = ''
    $ffmpegOK = 'SKIP'
    $ffmpegErr = ''

    # If master playlist, find the highest BANDWIDTH variant and use its URL
    $variantUrl = $url
    if ($hasMaster -and $text) {
        $lines = $text -split "`n"
        $best = $null
        for ($i=0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match 'BANDWIDTH=(\d+)') {
                $bw = [int]$matches[1]
                $res = ''
                if ($lines[$i] -match 'RESOLUTION=(\d+x\d+)') { $res = $matches[1] }
                # variant is next non-empty non-comment line
                $j = $i + 1
                while ($j -lt $lines.Length -and ($lines[$j] -match '^#' -or [string]::IsNullOrWhiteSpace($lines[$j]))) { $j++ }
                if ($j -lt $lines.Length) {
                    $candidate = $lines[$j].Trim()
                    if ($best -eq $null -or $bw -gt $best.bw) { $best = [PSCustomObject]@{ bw=$bw; res=$res; url=$candidate } }
                }
            }
        }
        if ($best -ne $null) {
            $topBw = $best.bw
            $topRes = $best.res
            try {
                # Resolve relative variant url
                $base = [uri]$url
                $variantUrl = (New-Object System.Uri($base, $best.url)).AbsoluteUri
            } catch {
                $variantUrl = $best.url
            }
        }
    }

    # Use ffprobe if present
    if (CommandExists 'ffprobe') {
        try {
            $ffOut = ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,bit_rate,width,height -of default=noprint_wrappers=1:nokey=1 "$variantUrl" 2>&1
            if ($LASTEXITCODE -eq 0) {
                $probeOK = 'OK'
                $parts = $ffOut -split "`n"
                if ($parts.Length -ge 1) { $probeCodec = $parts[0] }
                if ($parts.Length -ge 2) { $probeBitrate = $parts[1] }
                if ($parts.Length -ge 3) { $probeWidth = $parts[2] }
                if ($parts.Length -ge 4) { $probeHeight = $parts[3] }
            }
        } catch {
            $probeOK = 'ERR'
        }
    }

    # If ffprobe not available, attempt to measure throughput by downloading first N segments
    $segmentSizes = @()
    $segmentTimes = @()
    if (-not (CommandExists 'ffprobe')) {
        try {
            # Find a variant or segment in manifest text
            $candidateUrl = $variantUrl
            if ($text -and $text -match '#EXTINF') {
                # find first segment URL (line after #EXTINF)
                $lines = $text -split "`n"
                for ($i=0; $i -lt $lines.Length; $i++) {
                    if ($lines[$i] -match '^#EXTINF') {
                        # next line should be segment
                        $j = $i + 1
                        while ($j -lt $lines.Length -and ($lines[$j] -match '^#' -or [string]::IsNullOrWhiteSpace($lines[$j]))) { $j++ }
                        if ($j -lt $lines.Length) { $candidateUrl = (New-Object System.Uri((New-Object System.Uri($url)), $lines[$j].Trim())).AbsoluteUri; break }
                    }
                }
            }
            for ($s = 0; $s -lt $SegmentCount; $s++) {
                try {
                    $wc = [System.Diagnostics.Stopwatch]::StartNew()
                    $r = Invoke-WebRequest -Uri $candidateUrl -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop
                    $wc.Stop()
                    if ($r -and $r.RawContentLength -gt 0) {
                        $segmentSizes += $r.RawContentLength
                        $segmentTimes += [math]::Round($wc.Elapsed.TotalMilliseconds)
                    }
                } catch {
                    break
                }
            }
        } catch {
            # ignore
        }
    }

    # Use ffmpeg to try to capture a few seconds
    if (CommandExists 'ffmpeg') {
        try {
            $log = ffmpeg -y -timeout 3000000 -i "$variantUrl" -t 8 -c copy -f null NUL 2>&1
            $code = $LASTEXITCODE
            if ($code -eq 0) { $ffmpegOK = 'OK' } else { $ffmpegOK = 'ERR' }
            if ($ffmpegOK -eq 'ERR') { $ffmpegErr = $log -join "`n" }
        } catch {
            $ffmpegOK = 'ERR'
            $ffmpegErr = $_.Exception.Message
        }
    }

    $avgSize = ''
    $avgTime = ''
    if ($segmentSizes.Count -gt 0) {
        $avgSize = [math]::Round(($segmentSizes | Measure-Object -Sum).Sum / $segmentSizes.Count)
        $avgTime = [math]::Round(($segmentTimes | Measure-Object -Sum).Sum / $segmentTimes.Count)
    }
    "$url,$status,$hasMaster,$topBw,$topRes,$probeOK,$probeCodec,$probeBitrate,$probeWidth,$probeHeight,$ffmpegOK,`"$ffmpegErr`",$avgSize,$avgTime" | Out-File -FilePath $OutputFile -Append

    Write-Output "Result saved for $url"
}

Write-Output "Results written to $OutputFile"

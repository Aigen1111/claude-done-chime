# Windows fallback player for Claude Done-Chime, used when neither ffplay nor mpv is
# installed. It plays WAV, MP3, M4A/AAC, MP4, WMA and FLAC. It does not play OGG or
# Opus: install ffplay (FFmpeg) or mpv for those.
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [int]$Volume = 80,
    [int]$MaxSeconds = 10
)

Add-Type -AssemblyName PresentationCore
$player = New-Object System.Windows.Media.MediaPlayer
$player.Volume = [Math]::Max(0, [Math]::Min(100, $Volume)) / 100
$player.Open([Uri]$Path)

# Open is asynchronous: wait up to 3 s for the length to be known. If it never is,
# the format is not supported and nothing would play.
for ($i = 0; $i -lt 30 -and -not $player.NaturalDuration.HasTimeSpan; $i++) {
    Start-Sleep -Milliseconds 100
}
if (-not $player.NaturalDuration.HasTimeSpan) {
    $player.Close()
    exit 0
}

$player.Play()
$ms = $player.NaturalDuration.TimeSpan.TotalMilliseconds + 250
Start-Sleep -Milliseconds ([Math]::Min($ms, $MaxSeconds * 1000))
$player.Close()

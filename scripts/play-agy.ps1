# Antigravity CLI hook handler for Done-Chime (Windows).
# Reads Antigravity hook JSON from stdin, plays the matching sound detached
# (without blocking the synchronous hook loop or inheriting stdout pipes),
# and writes the required JSON decision to stdout.
param(
    [ValidateSet("stop", "attention", "error", "done")]
    [string]$Event = "stop"
)

$ErrorActionPreference = "SilentlyContinue"
$MaxSeconds = 10

function Get-Opt([string]$Key, [string]$Default) {
    $v = [Environment]::GetEnvironmentVariable("DONE_CHIME_$Key")
    if ([string]::IsNullOrWhiteSpace($v)) {
        $v = [Environment]::GetEnvironmentVariable("CLAUDE_PLUGIN_OPTION_$Key")
    }
    if ([string]::IsNullOrWhiteSpace($v)) { return $Default }
    return $v
}

# Read hook JSON payload from stdin
$payload = $null
try {
    $rawInput = [Console]::In.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
        $payload = $rawInput | ConvertFrom-Json
    }
} catch {}

# Map Antigravity event + terminationReason to sound name
$soundName = $null
switch ($Event) {
    "stop" {
        $reason = if ($payload -and $payload.terminationReason) { [string]$payload.terminationReason } else { "" }
        if ($reason -eq "USER_CANCELED") {
            $soundName = $null
        } elseif ($reason -eq "ERROR") {
            $soundName = "error"
        } else {
            $soundName = "done"
        }
    }
    "attention" { $soundName = "attention" }
    "error"     { $soundName = "error" }
    "done"      { $soundName = "done" }
}

# Respect mute and per-event toggle
$playFlag = if ($soundName) { (Get-Opt ("PLAY_" + $soundName.ToUpper()) "true").ToLower() } else { "false" }
$volRaw = Get-Opt "VOLUME" "80"
$vol = 80
if ($volRaw -match '^\d+') { $vol = [Math]::Min(100, [int]$Matches[0]) }

if ($soundName -and $playFlag -ne "false" -and -not $env:DONE_CHIME_MUTE -and $vol -gt 0) {
    $root = if ($env:PLUGIN_ROOT) { $env:PLUGIN_ROOT } else { Split-Path -Parent $PSScriptRoot }

    # Custom sound file override, falling back to pack
    $custom = Get-Opt ($soundName.ToUpper() + "_SOUND") ""
    if ($custom -like "~/*" -or $custom -like "~\*") {
        $custom = Join-Path $HOME $custom.Substring(2)
    }

    $soundPath = $null
    if (-not [string]::IsNullOrWhiteSpace($custom) -and (Test-Path -LiteralPath $custom)) {
        $soundPath = $custom
    } else {
        $pack = Get-Opt "SOUND_PACK" "chime"
        $candidate = Join-Path $root "sounds\$pack\$soundName.wav"
        if (-not (Test-Path -LiteralPath $candidate)) {
            $candidate = Join-Path $root "sounds\chime\$soundName.wav"
        }
        if (Test-Path -LiteralPath $candidate) {
            $soundPath = $candidate
        }
    }

    if ($soundPath) {
        $ffplay = Get-Command ffplay.exe -ErrorAction SilentlyContinue
        $mpv = if (-not $ffplay) { Get-Command mpv.exe -ErrorAction SilentlyContinue } else { $null }

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.UseShellExecute = $true
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        if ($ffplay) {
            $psi.FileName = $ffplay.Source
            $psi.Arguments = "-nodisp -autoexit -loglevel quiet -volume $vol -t $MaxSeconds `"$soundPath`""
        } elseif ($mpv) {
            $psi.FileName = $mpv.Source
            $psi.Arguments = "--no-video --really-quiet --volume=$vol --length=$MaxSeconds `"$soundPath`""
        } else {
            $fallback = Join-Path $PSScriptRoot "play-windows.ps1"
            $psi.FileName = "powershell.exe"
            $psi.Arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$fallback`" -Path `"$soundPath`" -Volume $vol -MaxSeconds $MaxSeconds"
        }

        try {
            [System.Diagnostics.Process]::Start($psi) | Out-Null
        } catch {}
    }
}

# Output required JSON contract for Antigravity CLI hooks
if ($Event -eq "attention") {
    Write-Output '{"decision":"allow"}'
} else {
    Write-Output '{"decision":"stop"}'
}
exit 0

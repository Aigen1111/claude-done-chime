#!/usr/bin/env bash
# Plays one of the plugin's sounds: done, attention or error.
# Never fails the hook: a missing player or a muted session just stays silent.
# The player runs in the background so the hook returns at once and the sound
# survives the end of the session (claude -p exits right after the reply).

name="${1:-done}"
[ -n "$DONE_CHIME_MUTE" ] && exit 0

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
file="$root/sounds/$name.wav"
[ -f "$file" ] || exit 0

play() {
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*)
      command -v cygpath >/dev/null 2>&1 && file="$(cygpath -w "$file")"
      file="${file//\'/\'\'}"
      powershell.exe -NoProfile -NonInteractive -Command \
        "(New-Object System.Media.SoundPlayer '$file').PlaySync()"
      ;;
    Darwin)
      afplay "$file"
      ;;
    *)
      for player in pw-play paplay aplay; do
        if command -v "$player" >/dev/null 2>&1; then
          "$player" "$file"
          break
        fi
      done
      ;;
  esac
}

play </dev/null >/dev/null 2>&1 &
exit 0

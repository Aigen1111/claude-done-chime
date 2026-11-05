#!/usr/bin/env bash
# Claude Done-Chime player.
#
#   play.sh done|attention|error   from the hooks; options come from CLAUDE_PLUGIN_OPTION_*
#   play.sh mark                   from UserPromptSubmit: remembers when the turn started
#   play.sh preview PACK VOLUME [DONE] [ATTENTION] [ERROR]
#                                  plays the three sounds in a row, ignoring the on/off options
#
# A hook never fails because of this script: a muted session, a missing file or a
# missing player just stays silent. Hook sounds play in the background, so the hook
# returns at once and the sound survives the end of the session (claude -p).

MAX_SECONDS=10
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
state_dir="${TMPDIR:-/tmp}"

is_windows() {
  case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) return 0 ;; esac
  return 1
}

# opt KEY DEFAULT: the plugin option CLAUDE_PLUGIN_OPTION_KEY, or DEFAULT when unset or empty.
opt() {
  local name="CLAUDE_PLUGIN_OPTION_$1"
  printf '%s' "${!name:-$2}"
}

# Reads the hook input on stdin and prints its session_id (letters, digits and dashes only).
session_id() {
  tr -d '\r\n' | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr -cd 'A-Za-z0-9-'
}

volume() {
  local v
  v="$(opt VOLUME 80)"
  v="${v%%.*}"
  case "$v" in '' | *[!0-9]*) v=80 ;; esac
  [ "$v" -gt 100 ] && v=100
  printf '%s' "$v"
}

# sound_file EVENT: the custom file for EVENT if it exists, otherwise the pack's own sound.
sound_file() {
  local event="$1" key custom pack
  key="$(printf '%s_SOUND' "$event" | tr '[:lower:]' '[:upper:]')"
  custom="$(opt "$key" "")"
  case "$custom" in "~"/*) custom="$HOME/${custom#\~/}" ;; esac
  if [ -n "$custom" ]; then
    is_windows && command -v cygpath >/dev/null 2>&1 && custom="$(cygpath -u "$custom")"
    if [ -f "$custom" ]; then
      printf '%s' "$custom"
      return
    fi
  fi
  pack="$(opt SOUND_PACK chime)"
  [ -d "$root/sounds/$pack" ] || pack=chime
  printf '%s' "$root/sounds/$pack/$event.wav"
}

# play_file FILE VOLUME: plays any format the first available player understands.
play_file() {
  local file="$1" vol="$2"
  [ -f "$file" ] && [ "$vol" -gt 0 ] || return 0
  is_windows && command -v cygpath >/dev/null 2>&1 && file="$(cygpath -w "$file")"

  if command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet -volume "$vol" -t "$MAX_SECONDS" "$file"
  elif command -v mpv >/dev/null 2>&1; then
    mpv --no-video --really-quiet --volume="$vol" --length="$MAX_SECONDS" "$file"
  elif is_windows; then
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass \
      -File "$(cygpath -w "$root/scripts/play-windows.ps1")" \
      -Path "$file" -Volume "$vol" -MaxSeconds "$MAX_SECONDS"
  elif [ "$(uname -s)" = Darwin ]; then
    afplay -v "$(awk "BEGIN { print $vol / 100 }")" -t "$MAX_SECONDS" "$file"
  elif command -v pw-play >/dev/null 2>&1; then
    pw-play --volume="$(awk "BEGIN { print $vol / 100 }")" "$file"
  elif command -v paplay >/dev/null 2>&1; then
    paplay --volume="$((vol * 65536 / 100))" "$file"
  elif command -v aplay >/dev/null 2>&1; then
    aplay -q "$file"
  fi
}

event="${1:-done}"
[ -n "$DONE_CHIME_MUTE" ] && [ "$event" != preview ] && exit 0

case "$event" in
  mark)
    min="$(opt MIN_SECONDS 0)"
    [ "${min%%.*}" -gt 0 ] 2>/dev/null || exit 0
    id="$(session_id)"
    [ -n "$id" ] && date +%s >"$state_dir/claude-done-chime-$id"
    exit 0
    ;;

  preview)
    export CLAUDE_PLUGIN_OPTION_SOUND_PACK="$2" CLAUDE_PLUGIN_OPTION_VOLUME="$3" \
      CLAUDE_PLUGIN_OPTION_DONE_SOUND="$4" CLAUDE_PLUGIN_OPTION_ATTENTION_SOUND="$5" \
      CLAUDE_PLUGIN_OPTION_ERROR_SOUND="$6"
    vol="$(volume)"
    for e in done attention error; do
      file="$(sound_file "$e")"
      echo "$e: $file (volume $vol)"
      play_file "$file" "$vol" >/dev/null 2>&1
    done
    exit 0
    ;;

  done | attention | error)
    flag="$(printf 'PLAY_%s' "$event" | tr '[:lower:]' '[:upper:]')"
    [ "$(opt "$flag" true)" = false ] && exit 0

    if [ "$event" = done ]; then
      min="$(opt MIN_SECONDS 0)"
      min="${min%%.*}"
      if [ "$min" -gt 0 ] 2>/dev/null; then
        start_file="$state_dir/claude-done-chime-$(session_id)"
        if [ -f "$start_file" ]; then
          elapsed=$(($(date +%s) - $(cat "$start_file")))
          rm -f "$start_file"
          [ "$elapsed" -lt "$min" ] && exit 0
        fi
      fi
    fi

    file="$(sound_file "$event")"
    vol="$(volume)"
    play_file "$file" "$vol" </dev/null >/dev/null 2>&1 &
    exit 0
    ;;
esac

exit 0

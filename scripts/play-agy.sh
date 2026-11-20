#!/usr/bin/env bash
# Antigravity CLI hook handler for Done-Chime (macOS / Linux).
# Reads Antigravity hook JSON from stdin, delegates detached audio playback
# to play.sh, and writes the required JSON decision to stdout.

event="${1:-stop}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
root="${PLUGIN_ROOT:-$(cd "$script_dir/.." && pwd)}"

payload="$(cat 2>/dev/null || true)"

sound_event=""
case "$event" in
  stop)
    reason="$(printf '%s' "$payload" | tr -d '\r\n' | sed -n 's/.*"terminationReason"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
    case "$reason" in
      USER_CANCELED) sound_event="" ;;
      ERROR)         sound_event="error" ;;
      *)             sound_event="done" ;;
    esac
    ;;
  attention | error | done)
    sound_event="$event"
    ;;
esac

# Forward DONE_CHIME_* env overrides into play.sh's CLAUDE_PLUGIN_OPTION_* variables
export CLAUDE_PLUGIN_ROOT="$root"
[ -n "$DONE_CHIME_SOUND_PACK" ]      && export CLAUDE_PLUGIN_OPTION_SOUND_PACK="$DONE_CHIME_SOUND_PACK"
[ -n "$DONE_CHIME_VOLUME" ]          && export CLAUDE_PLUGIN_OPTION_VOLUME="$DONE_CHIME_VOLUME"
[ -n "$DONE_CHIME_PLAY_DONE" ]       && export CLAUDE_PLUGIN_OPTION_PLAY_DONE="$DONE_CHIME_PLAY_DONE"
[ -n "$DONE_CHIME_PLAY_ATTENTION" ]  && export CLAUDE_PLUGIN_OPTION_PLAY_ATTENTION="$DONE_CHIME_PLAY_ATTENTION"
[ -n "$DONE_CHIME_PLAY_ERROR" ]      && export CLAUDE_PLUGIN_OPTION_PLAY_ERROR="$DONE_CHIME_PLAY_ERROR"
[ -n "$DONE_CHIME_DONE_SOUND" ]      && export CLAUDE_PLUGIN_OPTION_DONE_SOUND="$DONE_CHIME_DONE_SOUND"
[ -n "$DONE_CHIME_ATTENTION_SOUND" ] && export CLAUDE_PLUGIN_OPTION_ATTENTION_SOUND="$DONE_CHIME_ATTENTION_SOUND"
[ -n "$DONE_CHIME_ERROR_SOUND" ]     && export CLAUDE_PLUGIN_OPTION_ERROR_SOUND="$DONE_CHIME_ERROR_SOUND"

if [ -n "$sound_event" ]; then
  bash "$script_dir/play.sh" "$sound_event" </dev/null >/dev/null 2>&1 || true
fi

if [ "$event" = "attention" ]; then
  printf '{"decision":"allow"}\n'
else
  printf '{"decision":"stop"}\n'
fi
exit 0

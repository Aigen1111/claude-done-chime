# Claude Done-Chime

A Claude Code plugin that plays a short sound so you can look away while Claude works:

| When | Sound |
|---|---|
| Claude finishes a reply (`Stop`) | finish: rising notes |
| Claude is waiting for your permission or a form (`Notification`) | attention: two quick notes |
| A reply stops on an API error (`StopFailure`) | error: falling notes |

Use your own sounds in almost any audio or video format, or pick one of three built-in packs. Works on Windows, macOS and Linux with no required dependencies.

*Unofficial community plugin, not made or endorsed by Anthropic. Its plugin name is `done-chime`.*

## Install

In Claude Code:

```
/plugin marketplace add Aigen1111/claude-done-chime
/plugin install done-chime@done-chime
```

Then run `/reload-plugins` or restart Claude Code. To hear your current sounds at any time:

```
/done-chime:preview
```

## Settings

Change them in `/config` or in `/plugin` › done-chime › Configure.

| Option | Default | What it does |
|---|---|---|
| Sound pack | `chime` | Built-in sounds: `chime` (bell), `soft` (gentle) or `arcade` (8-bit) |
| Volume | `80` | 0 to 100; 0 silences everything |
| Sound when Claude finishes / needs you / on errors | on | Turn each sound on or off |
| Minimum task length (seconds) | `0` | The finish sound only plays when the turn took at least this long, so quick answers stay quiet |
| Custom finish / attention / error sound | empty | Path to your own file; empty uses the pack |

To silence it for one session without changing the settings, start Claude with `DONE_CHIME_MUTE=1`:

```sh
DONE_CHIME_MUTE=1 claude
```

To turn it off for good: `/plugin` › done-chime › Disable.

## Custom sounds and formats

Any file is played for at most 10 seconds. The plugin uses the first player it finds:

1. **ffplay** (part of [FFmpeg](https://ffmpeg.org/)) or **mpv**: any format they can open, such as WAV, MP3, M4A/AAC, MP4, FLAC, OGG, Opus, WebM or MKV. Video files play their audio only.
2. Otherwise, the system player:
   - **Windows**: WAV, MP3, M4A/AAC, MP4, WMA and FLAC. For OGG or Opus, install FFmpeg (`winget install Gyan.FFmpeg`).
   - **macOS** (`afplay`): WAV, AIFF, MP3, M4A/AAC, FLAC and CAF.
   - **Linux**: `pw-play`, `paplay` or `aplay`. The formats depend on your system; WAV always works.

If a custom file doesn't exist, the pack sound plays instead.

## Notes

- The finish sound plays every time Claude hands control back to you, including when it asks you a question. Raise *Minimum task length* if that is too often.
- Claude Code sends the attention notification only when you seem to be away: after about six seconds without typing.
- Sounds also play in headless runs (`claude -p`). Use `DONE_CHIME_MUTE=1` in scripts.
- On Windows the hooks need Git Bash (Git for Windows).
- The built-in packs are synthesized by `tools/make-sounds.py` (Python standard library). Run `python tools/make-sounds.py` to rebuild them.

## License

MIT, including the sounds.

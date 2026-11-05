# done-chime

A Claude Code plugin that plays a short sound so you can look away while Claude works:

| When | Sound |
|---|---|
| Claude finishes a reply (`Stop`) | `done`: two rising notes |
| Claude is waiting for your permission or a form (`Notification`) | `attention`: two quick notes |
| A reply stops on an API error (`StopFailure`) | `error`: two falling notes |

Works on Windows (Git Bash + PowerShell), macOS (`afplay`) and Linux (`pw-play`, `paplay` or `aplay`). No dependencies.

## Install

In Claude Code:

```
/plugin marketplace add Aigen1111/done-chime
/plugin install done-chime@done-chime
```

Restart Claude Code (or run `/reload-plugins`).

## Mute

Set `DONE_CHIME_MUTE=1` in the environment to silence it, for example for one session:

```sh
DONE_CHIME_MUTE=1 claude
```

To turn it off for good: `/plugin` › done-chime › Disable.

## Notes

- `done` plays every time Claude stops and hands control back to you, including when it asks you a question.
- Claude Code sends the permission notification only when you seem to be away: after about six seconds without typing.
- It also plays in headless runs (`claude -p`). Use `DONE_CHIME_MUTE=1` in scripts.
- The sounds are synthesized by `tools/make-sounds.py`; run `python tools/make-sounds.py` to rebuild them. To use your own, replace the WAV files in `sounds/`.

## License

MIT, including the sounds.

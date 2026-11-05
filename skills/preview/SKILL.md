---
name: preview
description: Play the three Claude Done-Chime sounds (finish, attention, error) with the current settings
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/play.sh" preview *)
---

These sounds just played, in this order, with the user's current Claude Done-Chime settings:

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/play.sh" preview '${user_config.sound_pack}' '${user_config.volume}' '${user_config.done_sound}' '${user_config.attention_sound}' '${user_config.error_sound}'`

Tell the user in one or two short sentences which files played. If a custom file they set is not in the list, it was not found and the pack sound played instead: say so. Settings are in `/config` or `/plugin` › done-chime.

# Kitty Visual & Quality-of-Life — v1.6.0

This update incorporates selected ideas from the It's FOSS Kitty customization guide and validates them against Kitty's current configuration reference.

## JetBrains Mono

The pack prefers:

```conf
font_family JetBrains Mono
font_size 11.5
```

when the font is available.

Otherwise:

```conf
font_family monospace
```

The installer can install JetBrains Mono from supported distro repositories.

## Mouse

```conf
mouse_hide_wait -3.0
```

Negative values tell Kitty to hide the pointer immediately while typing.

## Notifications

```conf
notify_on_cmd_finish invisible 20.0
```

Notification conditions:

1. the shell command runs for at least 20 seconds;
2. the relevant Kitty window is not visible.

This avoids notification spam for short commands.

## Scrollback

```conf
scrollback_lines 20000
scrollback_pager_history_size 16
```

The first value controls normal interactive scrollback.

The second is a separate history buffer measured in MB and used only when opening Kitty's scrollback pager.

Shortcut:

```text
Ctrl+Space, H
```

## Tabs

```conf
tab_bar_style powerline
tab_powerline_style round
```

Rounded Powerline tabs remain the default.

## Why no background image / watermark?

They are intentionally omitted. On a small coding display they reduce contrast and add visual noise without improving the workflow.

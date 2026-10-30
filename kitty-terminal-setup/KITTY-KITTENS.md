# Kitty Kittens & Developer Extras

## File picker

```text
Ctrl+Space, E
```

Choose a file and insert it at the shell prompt.

```text
Ctrl+Space, D
```

Choose a directory.

Favorite picker jumps:

```text
Alt+D  ~/dev
Alt+U  Unified Frontend
```

## Quick Access Terminal

Inside Kitty:

```text
Ctrl+Space, Q
```

Global command:

```text
~/.local/bin/kitty-quick-access
```

Recommended desktop shortcut:

```text
Super + `
```

## Diff

```bash
kd old.ts new.ts
```

or:

```bash
kitten diff old.ts new.ts
```

## Images

```bash
img cover.png
```

or:

```bash
kitten icat cover.png
```

## Hyperlinked grep

```bash
hg "search text"
```

Modern `rg` automatically gets Kitty hyperlinks when supported.

## SSH

```bash
kssh server
```

## File transfer over Kitty SSH

```bash
ktransfer
```

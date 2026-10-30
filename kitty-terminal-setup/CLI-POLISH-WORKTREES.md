# CLI Polish & Git Worktrees — v1.6.0

## eza

```bash
ls
ll
la
l
tree
tree3
```

`ll` includes Git status information when eza is installed.

## bat

`cat` is intentionally unchanged.

```bash
b src/file.ts
bp src/file.ts
```

## delta

Git automatically routes diff output through delta after installation.

Useful examples:

```bash
gd
gds
git show
git log -p
git stash show -p
```

In delta:

```text
n    next diff section
N    previous diff section
```

## lazygit

Optional:

```bash
lg
```

## Worktrees

### List

```bash
gwl
```

### Create and enter

```bash
gwnew feature/foo
```

Optional start point:

```bash
gwnew feature/foo main
```

### Select and enter

```bash
gwcd
```

### Remove

```bash
gwrm
```

The helper refuses dirty/main/current worktrees and never deletes the branch.

### Prune stale metadata

```bash
gwprune
```

## Directory layout

Linked worktrees are placed beside the main repository:

```text
project/
project-worktrees/
  feature-one/
  hotfix-two/
```

This keeps them outside the main repository and avoids polluting its working tree.

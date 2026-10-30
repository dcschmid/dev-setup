# Node / NVM / pnpm auf Fedora (Framework 16)

Das Oh-My-Zsh-Plugin `nvm` stellt **keine Node-Installation** bereit.
Unser Zsh-Profil kann `.nvmrc` nur dann automatisch aktivieren, wenn
`~/.nvm/nvm.sh` existiert und die Node-Version schon installiert ist.

## Diagnose (keine Änderungen)

```bash
./setup-node.sh --check
```

## NVM auf Wunsch installieren

```bash
./setup-node.sh --install-nvm
```

Installiert explizit upstream nvm v0.40.8 ohne fremde Ergänzungen in
`.zshrc`. Danach einen **neuen Kitty-Tab** öffnen.

## Projektversion installieren

```bash
./setup-node.sh --install-project
```

Falls `~/dev/gitlab/unified-frontend/.nvmrc` vorhanden ist, fragt das Script
vor `nvm install` nach. Ohne `.nvmrc` wird bewusst **keine Version geraten**.

## pnpm und Corepack

Nutze zunächst die im Repo definierte `packageManager`-Version.
Corepack war Node 14.19 bis vor Node 25 beigelegt; bei neueren
Versionen ist gegebenenfalls `npm install -g corepack` erforderlich.
Vor `corepack enable pnpm` prüfen, ob bereits eine separate `pnpm`-
Installation vorhanden ist: globale Installationen und Corepack-Shims
können sonst konkurrieren. Auch bei einem NVM-Versionswechsel können
separate Corepack-Shims notwendig sein.

## Fehlende optionale Tools

`uv`, `cargo`, `conda`, `codex`, `claude` und `omp` werden vom Doctor
als **optional** beschrieben; `omp` steht in diesem Umfeld für
Oh My Pi, nicht für den Zsh-Prompt. Ohne Bedarf wird nichts installiert.

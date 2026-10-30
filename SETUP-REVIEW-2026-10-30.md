# Development setup review — 2026-10-30

This is the original pre-change review. The implementation status is recorded at the end; installed state has subsequently been updated with the user's authorization.

The most useful next step is to repair configuration drift and improve verification. The existing skills are mostly concise and well scoped. Adding many more skills would currently provide less value than making the existing policies and tools work consistently.

This review covers the repository, the installed agent profiles, all 14 stack-owned skill definitions, metadata and size checks for 42 cached plugin skill files, selected upstream skill candidates, terminal/editor diagnostics, and published tool versions. Cached plugin files are not necessarily active skills. This is not a line-by-line audit of every vendor plugin, project, or operating-system package.

During the initial review only this report was added. The findings and version table below describe that initial state.

## Verified health

| Check | Result |
| --- | --- |
| Kitty/Zsh live diagnostic | 28 successful checks, no warnings or failures |
| Zed live diagnostic | Core tools, config, extensions, font and Java present; optional Yarn/Bun absent |
| Kitty unit tests | 2 passed |
| Zed unit tests | 4 passed |
| Agent stack smoke suites | All 6 passed in temporary fixtures |
| Claude/Codex TinyContext registration | Passed for Working and Private; distinct profile database paths |
| Basic OMP profile/MCP/skill checks | Passed; Blender registered only in Private |
| Full installed-profile verification | Failed: missing two OMP aliases, remaining Zed Delta installation, and OMP feature ownership check |

Passing fixture tests do not establish that the current installed configuration passes verification. The findings below explain the difference. Editor and terminal checks did not include a manual visual session or a game/browser runtime test.

## Priority 1: repair observable failures

### 1. Zed Delta shadows Git's diff pager

The shell resolves `delta` to `~/.local/delta.app/bin/delta` through `~/.local/bin/delta`. Its help identifies the Zed Delta application CLI. Git is configured with `core.pager=delta` and `interactive.diffFilter=delta --color-only`.

The resulting behavior is directly reproducible with empty input:

| Command | Exit | Behavior |
| --- | --- | --- |
| `delta --color-only` | 2 | Rejects `--color-only` |
| `/usr/bin/delta --color-only` | 0 | Correct Git diff filter |

The current [shell doctor](kitty-terminal-setup/shell-doctor.sh) only checks that `delta` exists, so its green result misses this collision. The [Zed Delta cleanup scanner](frontend-ai-optimized-stack/scripts/cleanup_zed_delta.py) correctly identifies the app, CLI link, desktop entry and Claude plugin still installed.

**Recommendation:** complete the already documented Zed Delta removal, preserving the system Git Delta package, then verify command resolution and Git's filter. If the Zed application is intentionally kept, give its launcher a distinct name. Extend the shell doctor to check the pager's behavior or identity, rather than command presence alone.

### 2. OMP feature checks reject otherwise valid installed settings

`setup-yolo-omp.sh --check` passes the basic profile checks and then fails on the Working feature configuration:

```text
user-owned YAML keys would collide with managed policy:
async, autolearn, bash, browser, computer, isolation, lsp, memory, task, tools
```

Both installed `config.yml` files contain those keys but lack the `BEGIN`/`END` comments used by [configure_omp_features.py](frontend-ai-optimized-stack/scripts/configure_omp_features.py) to recognize ownership. A YAML comparison that preserves YAML 1.2 scalar meanings shows that Working's feature values match the generated defaults. Private differs only in `computer.enabled: true`, which must be preserved as an existing per-profile choice.

OMP 18.14.0 reads settings as objects and writes them back through `stringifyYamlConfig`, which uses Bun's YAML serializer. This provides an explanation consistent with the missing comments; the exact historical write that removed them was not observed. See the upstream [settings persistence implementation](https://github.com/can1357/oh-my-pi/blob/v18.14.0/packages/coding-agent/src/config/settings.ts) and [YAML serializer](https://github.com/can1357/oh-my-pi/blob/v18.14.0/packages/utils/src/yaml-config.ts).

**Recommendation:** track ownership independently of comments and validate settings semantically. Add a narrow migration for recognized existing stack settings; retain browser/computer choices and reject genuinely foreign conflicting values. A separately managed config overlay is another option if precedence is explicitly defined. Add a regression test for an OMP-style parse/save cycle. Simply restoring comments would provide only a temporary fix.

The main profile installer invokes this preflight before its managed-file updates, so rerunning it unchanged will currently stop at the same conflict.

### 3. Installed OMP assets lag behind the repository

`omp-working` and `omp-private` are absent, although both are provided by this repository. Their `yolo-working` and `yolo-private` counterparts exist. The installed `mm-omp-code-workflow` still tells OMP to use `learn`; the repository correctly explains that `learn` is unavailable with native memory off.

**Recommendation:** after fixing the OMP configuration migration, install the current managed assets and rerun full verification. Retain the existing profile choices, logins and TinyContext databases.

## Priority 2: make policy and diagnostics match reality

### 4. Profile RULES.md files are not delivered to the clients

The [Private rules](frontend-ai-optimized-stack/payload/private/RULES.md) and [Working rules](frontend-ai-optimized-stack/payload/working/RULES.md) contain useful profile-wide constraints. However, the installer copies skill directories and executables, not these files, and none of the managed launchers references them. The inspected user/profile instruction-file locations also contain no corresponding managed instructions.

Some policies are repeated inside individual skills, but that does not establish that the complete profile rules are loaded for every task.

**Recommendation:** deliver a short profile policy through each client's supported instruction mechanism, preserving user instructions. Keep workflow details in skills. Add verification that demonstrates which policy source each profile actually loads. Check the current client documentation before choosing the injection mechanism.

### 5. Global MCP registrations include broken private-project commands

Codex and Claude contain global `riff-asset-forge` registrations whose executable is missing. Claude also has a missing `riff-asset-forge-clean` command. These were checked for executable availability without running them.

Working Codex's `config.toml` is a symlink to the Private/default Codex config, so it inherits these registrations despite its separate login and skill directory. The Blender-specific isolation check does not cover arbitrary additional private integrations.

**Recommendation:** remove or repair these exact stale registrations according to the intended projects, and scope project-specific tools to their projects or the intended profile. Give Working an explicit MCP policy rather than sharing every default registration. Preserve unrelated config and credentials. This finding concerns configuration inheritance; it is not evidence that employer data was transferred.

### 6. The skill audit provides an incomplete green result

The current [mm-skill-audit](frontend-ai-optimized-stack/payload/bin/mm-skill-audit) reports 13 files and zero warnings. It omits the OMP package group, installed system/plugin skills, installed-versus-repository drift, broken executable dependencies, and active-profile capability checks.

Its frontmatter parser also accepts a deliberately invalid skill with bare `name:` and `description:` lines and no YAML frontmatter delimiters. It always exits successfully, even when warnings are found. Standard recursive path traversal also needs explicit handling for symlinked skill directories.

**Recommendation:** add profile/client scope, OMP coverage, installed drift checks, symlink handling, real frontmatter validation, and an optional strict exit mode. Distinguish active plugins from inactive cached versions. Scan plugin files read-only and keep vendor-owned files out of stack-managed rewriting.

A supplemental size scan of all 42 cached plugin skill files found three large Figma entrypoints. This alone does not establish a defect; vendor workflows may need that detail. It does reinforce the case against installing another copy of the Figma skill suite.

### 7. Memory diagnostics do not yet verify all three clients

The shared memory skill correctly names Claude, Codex and OMP. The [memory doctor](frontend-ai-optimized-stack/payload/bin/mm-project-memory-doctor) checks only Claude/Codex registrations, and [the path resolver](frontend-ai-optimized-stack/payload/bin/mm-tinycontext-path) still prints `shared_clients=claude,codex`.

**Recommendation:** include OMP's selected profile MCP registration, the real Working Codex config path and the resolved project identity for all three clients. Continue to keep Working and Private database directories separate. No memory-backend replacement is needed.

### 8. Skill update paths duplicate logic and may duplicate plugin skills

[mm-stack-update](frontend-ai-optimized-stack/payload/bin/mm-stack-update) and [install-working-upstream-skills.sh](frontend-ai-optimized-stack/install-working-upstream-skills.sh) maintain separate copies of the Vercel/Figma download logic. The former can report a successful refresh after a clone even when the expected skill directory is absent. There is no installed upstream commit record on this machine, and Working currently has only the three bundled policy skills.

The present Codex session already exposes the official Figma plugin's 16 skills. Installing raw Figma copies as well could introduce duplicate or diverging instructions; availability must be checked separately for the intended Working client.

**Recommendation:** use one updater, validate expected files before reporting success, stage replacements before publishing them, record the exact commit, and run a scoped audit afterward. Refresh upstream skills only where they add a missing capability. Keep TinyContext, optional plugin updates and skill refreshes independently selectable.

### 9. Published checksum manifests are stale

`sha256sum --quiet -c SHA256SUMS.txt` fails for:

- Agent stack: `payload/omp/skills/mm-omp-code-workflow/SKILL.md`.
- Kitty package: `KEYBOARD-SHORTCUTS.md`, `NODE-SETUP.md`, `PERSISTENT-STATE.md`, and `README.md`.

These are observed manifest mismatches, not evidence of malicious changes. Regenerate the release manifests after reviewing the intended edits and check them in CI. Several doctor banners also still advertise older stack versions.

## Existing skills: targeted changes

The 14 owned definitions comprise 3 shared, 7 Private, 3 Working and 1 OMP-only skill. Most are small enough that additional reference folders or boilerplate would make them harder to maintain.

| Area | Recommendation |
| --- | --- |
| Astro-first and Astro content | Keep separate. Add an official-web-docs fallback when Astro Docs MCP is unavailable. |
| Defold development and runtime QA | Keep separate; engineering and runtime verification have different purposes. |
| Game project engineering and gamedev core | Consolidate their overlapping general workflow guidance while retaining the useful runtime contracts. |
| TinyContext | Keep as the single curated project-memory store; update the diagnostics. |
| Figma/Code Connect and Storybook | Keep the project source-of-truth policies; verify real tool availability per client. |
| GitHub/GitLab | Support the available authenticated MCP or CLI instead of assuming an MCP exists. |
| Firefox validation | Keep the browser preference; connect it to a usable Playwright tool or repository test command. |
| Semgrep | Keep for relevant changes; prefer repository rules and document the actual scan command when configured. |

GitHub, GitLab, Astro Docs and Playwright MCP tools are not exposed in this session. `gh`, `glab`, `playwright-cli` and ShellCheck are also absent from PATH; Semgrep is installed. Project-local tooling can change these results, so this is not a claim about every repository.

This approach follows current OpenAI guidance to keep skill descriptions focused, preserve explicit user intent and avoid unnecessary duplicate instructions. See [Build skills](https://learn.chatgpt.com/docs/build-skills) and [skill instruction guidance](https://developers.openai.com/plugins/build/skills).

## Useful additions, in order

1. **A working Playwright/Firefox execution path.** This fills an actual capability gap behind an existing policy. The official [Playwright skill](https://github.com/openai/skills/blob/main/skills/.curated/playwright/SKILL.md) and [Microsoft CLI](https://github.com/microsoft/playwright-cli) are candidates. The CLI supports a Firefox browser configuration. Preserve repository tests and browser settings; the skill alone does not install or verify a browser runtime.
2. **CI failure triage, scoped to each forge.** Use the official [gh-fix-ci](https://github.com/openai/skills/blob/main/skills/.curated/gh-fix-ci/SKILL.md) as a starting point for Private GitHub Actions, with a separate GitLab route for Working. Its current instructions require an additional plan-approval step; adapt that to respect an already authorized fix request. An authenticated CLI/MCP is a prerequisite; `gh` is currently absent.
3. **PR/MR review follow-up.** [gh-address-comments](https://github.com/openai/skills/blob/main/skills/.curated/gh-address-comments/SKILL.md) offers reusable retrieval helpers. Its blanket escalation and comment-selection prompts need adaptation to the actual environment and already specified scope. Add a GitLab equivalent only when the Working workflow needs it.
4. **Working React/composition guidance where missing.** The official [Vercel skills](https://github.com/vercel-labs/agent-skills/tree/main/skills) are reasonable package fallbacks for React projects. Keep Figma and repository components authoritative and avoid exposing them as Private Astro defaults.

Optional later additions are [security-threat-model](https://github.com/openai/skills/blob/main/skills/.curated/security-threat-model/SKILL.md) for explicitly requested architecture security reviews and [cli-creator](https://github.com/openai/skills/blob/main/skills/.curated/cli-creator/SKILL.md) for building durable CLI products. Neither is needed for ordinary small script maintenance. Extra memory backends, another web-search service and another Figma suite have no demonstrated benefit here.

## Tool versions checked against published releases

Versions were queried from the installed executables and upstream GitHub release APIs on 2026-10-30. These are point-in-time results, not permanent pins.

| Tool | Installed | Published release | Recommendation |
| --- | --- | --- | --- |
| Codex CLI | 0.166.0 | [0.166.0](https://github.com/openai/codex/releases/tag/rust-v0.166.0) | Current |
| Claude Code | 2.1.314 | [2.1.314](https://github.com/anthropics/claude-code/releases/tag/v2.1.314) | Current |
| OMP | 18.14.0 | [18.14.0](https://github.com/can1357/oh-my-pi/releases/tag/v18.14.0) | Current; fix configuration handling |
| Kitty | 0.49.2 | [0.49.2](https://github.com/kovidgoyal/kitty/releases/tag/v0.49.2) | Current |
| Zed | 1.26.2 | [1.26.2](https://github.com/zed-industries/zed/releases/tag/v1.26.2) | Current |
| uv | 0.13.4 | [0.13.6](https://github.com/astral-sh/uv/releases/tag/0.13.6) | Routine update candidate |
| Semgrep | 1.182.1 | [1.183.0](https://github.com/semgrep/semgrep/releases/tag/v1.183.0) | Routine update candidate |

GitHub MCP Server [2.0.3](https://github.com/github/github-mcp-server/releases/tag/v2.0.3) is published, but there is no GitHub MCP exposed in this session. A version advisory in the stack does not prove that an old server is installed. Keep the existing major-upgrade compatibility review if that integration is introduced or changed.

## Suggested implementation order

1. Restore Git's intended Delta executable and verify its filter behavior.
2. Fix OMP semantic ownership/migration, preserving the existing Private computer toggle.
3. Install the current managed aliases and OMP skill, then require full profile verification to pass.
4. Deliver profile rules, repair the stale MCP registrations and make Working tool scope explicit.
5. Improve skill/memory diagnostics, unify skill refresh logic and refresh checksums.
6. Update uv/Semgrep through their actual installation mechanisms and add only the skill/tool combinations needed for real workflows.

The useful maintenance automation here is CI running the existing six smoke suites and six unit tests, plus manifest verification and focused regressions for the failures above. ShellCheck would add value for the many Bash entrypoints. Broader new frameworks or services are not necessary to achieve these improvements.

## Implementation completed — 2026-10-30

The authorized maintenance changes are implemented in the repository and installed locally as stack **v3.14.0**.

| Original finding | Result |
| --- | --- |
| Zed Delta/Git Delta collision | Zed app/plugin moved into the recoverable installer backup; `delta` now resolves to `/usr/bin/delta`, and `--color-only` succeeds |
| OMP comment-based ownership | Semantic YAML recognition, supported toggle preservation, independent policy metadata and save-cycle regression coverage |
| Missing OMP aliases/stale skill | Both aliases installed; corrected OMP skill installed |
| Undelivered profile rules | Codex managed `AGENTS.md` blocks and appended Claude/OMP prompts installed |
| Shared Working Codex config | Independent Working config materialized, common MCPs inherited at migration; Working-owned additions preserved |
| Missing Asset Forge executables | Three exact stale global registrations removed; unrelated configuration retained |
| Incomplete skill/memory checks | Strict YAML/OMP/plugin-cache/drift checks and all-three-client memory verification installed |
| Duplicated updater | One validated, staged updater with commit records and recoverable prior directories; OMP uses the common skill resolver |
| Invalid skill metadata | Three pre-existing descriptions containing unquoted colons corrected |
| Stale manifests | Both package checksum manifests regenerated and verified |

The shared `mm-ci-triage` and `mm-review-followup` skills preserve existing authorization and support GitHub/GitLab tools. The official Playwright skill was imported at commit `49f948faa9258a0c61caceaf225e179651397431` and adapted for the pinned stack launcher. The overlapping gamedev-core definition was consolidated into game-project-engineering. There are now 16 bundled skill definitions.

Working Vercel React/composition skills were installed at upstream commit `1a2c79d4e6c4a2283dc2c614b6538cbe1ed5ca62`. Additional raw Figma skills were not installed because the existing plugin already supplies those workflows.

Installed tools: uv **0.13.6**, Semgrep **1.183.0**, GitHub CLI **2.103.3**, GitLab CLI **1.126.0**, ShellCheck **0.11.0**, and Playwright CLI **0.1.22** with Firefox **156.0**. Forge binaries were verified against pinned SHA256 digests; forge authentication remains account-specific.

Validation passed: 11 Python unit tests, all 6 Bash smoke suites, ShellCheck on maintained shell entrypoints, strict skill audit, full installed-profile verification, and package manifest checks. A real headless Firefox session identified its browser type as `firefox` and verified a button changing from `0` to `1` after a click. The test browser was closed and its temporary repository snapshots removed. No model inference was used for validation.

Semgrep's Python rules parsed all selected maintenance files. Three generic tainted-argument findings were reviewed: the memory doctor's fixed resolver command with explicit project/profile arguments; the upstream updater's fixed Git command with a branch/ref argument; and the tool installer's fixed, checksum-verified Playwright executable. These calls pass argument arrays with no shell. They do not concatenate data into executable shell text. The initial broader scan also flagged `0700` backup-directory permissions; changing these to the suggested world-readable `0644` would be inappropriate for a directory holding sensitive config backups. These are documented false positives, not suppressed security failures.

Recovery files are under:

```text
~/.frontend-ai-stack-backups/20261030-202700-98352-v3.14.0-omp-delta-cleanup/
```

Profile rollback is provided by `rollback-profiles.sh`; restoring the removed Zed Delta application/plugin remains a separate explicit operation as documented in `docs/ZED_DELTA_REMOVAL.md`. Existing logins and TinyContext databases were not migrated or replaced. The CI workflow is included for validation after publication; the results reported here were obtained locally.

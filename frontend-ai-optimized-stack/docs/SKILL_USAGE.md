# Using skills across Claude Code, Codex and OMP

A skill is a directory with a `SKILL.md` entry point and, sometimes, scripts,
references or templates. It gives an agent a workflow for a particular kind of
work. The agent still needs access to your files, the required tools and any
external service involved in the task.

Use a skill by naming it in your request. Describe the outcome, scope and checks
you expect. You can also let the agent select a skill from the available names
and descriptions when the task clearly needs it. Discovery does not mean every
skill should be loaded into every conversation.

## 1. Start the right client in the right repository

These are shell commands. Choose one launcher, rather than running all of them:

| Client | Personal repository | Work repository |
|---|---|---|
| Claude Code | `claude-private` | `claude-working` |
| Codex CLI | `codex-private` | `codex-working` |
| Oh My Pi / YOLO-Auto | `omp-private` | `omp-working` |

`yolo-private` and `yolo-working` are compatibility names for the OMP launchers.
OMP uses its own YOLO-Auto provider, credentials and workflow. It does not hand
planning, implementation or review to Claude or Codex.

```bash
cd ~/dev/github/dev-setup
codex-private
```

Once the conversation opens, enter:

```text
Use mm-stack-maintenance to verify my installed stack. Start with diagnostics,
report the failing checks, and identify the smallest repair that would address them.
```

For Claude or OMP, start `claude-private` or `omp-private` from the same checkout
and enter the same request. This plain-language form avoids depending on a
particular client's slash-command registration. A skill name is not a shell
command. A `/docs-readme` label inside a skill may describe a workflow without
being a registered slash command in your client.

Start a fresh wrapper session when changing repositories or profiles. In
particular, avoid using an agent's `-C` option to switch projects after the
wrapper has already selected its memory context.

## 2. Check what is actually available

There are three sources of skills:

| Source | Meaning | How it changes |
|---|---|---|
| This repository's payload | Stack-owned shared, profile-specific and OMP-only fallbacks | Install or refresh this stack |
| Your additional collection | Skills installed separately for a client or workspace | Use that collection's installation/update workflow |
| Plugins | Skills supplied through a client plugin | Manage the plugin in that client |

A skill available in your current Codex session may be absent from Claude or OMP.
Installing it in a personal skill directory does not establish that the Working
profile can see it. Plugin cache files also do not establish active availability.

From a project terminal, inspect the current installation:

```bash
mm-skill-audit --profile private --client codex --strict
mm-skill-audit --profile working --client omp --strict
mm-skill-audit --profile both --client all --plugins --strict
mm-skill-precedence-doctor private
```

The audit reads filesystem metadata and checks stack-owned drift. It does not
replace the running client's skill list. Ask the agent to confirm the exact
skill is available before relying on it. The audit also does not inventory every
possible third-party installation location.

### Skills bundled in this checkout

| Skill | Scope | Example request |
|---|---|---|
| `project-memory` | Both profiles, all three clients | “Recall the project decisions relevant to the authentication change.” |
| `mm-stack-maintenance` | Both profiles, all three clients | “Verify the stack and explain any installed-file drift.” |
| `mm-github-workflow` | Private | “Inspect the GitHub issue related to this bug and compare it with local code. Keep this read-only.” |
| `local-image-ai` | Private | “Discover the local image service's current models and presets, then generate a pixel-art prop concept in the project.” |
| `mm-gitlab-workflow` | Working | “Read the failing merge-request checks using the available GitLab integration and explain the failure.” |
| `mm-figma-source-of-truth` | Working | “Implement this view using the supplied Figma design, Code Connect mapping and existing components.” |
| `mm-storybook-workflow` | Working | “Find the existing component stories and update the relevant story for this behavior change.” |
| `mm-omp-code-workflow` | OMP only, both profiles | “Use OMP's native code workflow to inspect this change, implement it and run the repository checks.” |

GitHub/GitLab requests need an available authenticated integration or CLI for
private remote data. Figma requests need the design context and an appropriate
integration. The Storybook MCP requires the project's configured addon and a
running server. The local image skill requires the separately installed image
service. None of these skills creates account access by itself.

## 3. Examples for the additional skill collection

The following names refer to the additional collection used with this setup.
They are not bundled by `install-profiles.sh`. Use an example only when the
selected client lists its skills. Repository instructions and the selected
skill's own requirements still apply.

### Documentation and clear writing

```text
Use documentation-technical-writing and human-writing to rewrite all READMEs
in English. Keep factual details, explain setup and recovery, and add examples
that match the checked-in scripts. Verify local links and list unrun checks.
```

For a smaller change:

```text
Use human-writing to make the installation section clearer for a new teammate.
Keep the commands, paths, version numbers and technical meaning intact.
```

### Private Astro development

```text
Use astro to add a project page using this repository's existing conventions.
Use accessibility for keyboard and focus behavior. Keep the existing component
and styling approach, and run the checks already defined by the project.
```

The Private fallback is Astro-first. An existing repository's framework wins.
The Working profile excludes Astro-specific package guidance and follows its
company repository conventions.

### Existing React or Next.js work projects

```text
Use mm-figma-source-of-truth and mm-storybook-workflow to implement the supplied
Figma view. Reuse the Code Connect components and existing stories. Point out
missing design states before inventing variants or component APIs.
```

Optional Vercel Working guidance can help with React implementation and
composition. It does not override the project's design system or turn a private
Astro repository into a React project.

### Accessibility, browser checks and performance

```text
Use accessibility to inspect the checkout form's labels, errors, keyboard flow
and focus handling. Fix confirmed issues and distinguish automated evidence
from checks that still need a screen reader or manual review.
```

```text
Use ultimate-testing-qa and playwright to reproduce the broken filter flow in
Firefox, fix the cause, and rerun the affected flow. Include console and network
failures relevant to the bug. Use another browser only if the repository requires it.
```

```text
Use seo-performance to inspect this site's metadata, indexing rules and loading
performance. Measure what is available and identify checks that need deployment
access. Explain proposed changes before applying approval-gated fixes.
```

A browser skill does not install browsers or start the application automatically
in every environment. Supply the local URL or let the agent inspect the project's
existing development command.

### Review, security and maintenance

```text
Use ultimate-code-review to review my uncommitted changes. Keep it read-only,
prioritize bugs and regressions, and give file references and confidence for each
finding. State which checks you could not run.
```

```text
Use ci-triage to investigate this failed pipeline using the linked run and local
workflow files. Fix the confirmed cause and run the closest local check.
```

```text
Use review-followup to address the requested review comments. Check each comment
against the current code, apply the needed changes, and verify affected behavior.
```

```text
Use ultimate-security-hardening to investigate the authorization issue in this
endpoint. Confirm the failure before changing behavior. Use semgrep-security
for the configured deterministic scan and report any unavailable tooling.
```

```text
Use ultimate-code-quality-refactoring to audit the data-import module. Keep
this pass read-only and propose behavior-preserving changes with evidence.
```

### APIs, design systems and localization

```text
Use backend-api-engineering to add pagination to the existing list endpoint.
Follow the current API conventions and authorization model, update the contract,
and test boundary cases using the project's existing test setup.
```

```text
Use design-system-ui to audit duplicate colors, spacing and button styles.
Reuse existing tokens and propose a small migration. Preserve the current brand.
```

```text
Use ultimate-i18n-localization to audit English and German catalogs for missing
keys, placeholders and plural mismatches. Keep existing translations intact and
separate draft translations from approved copy.
```

### Private game development and image assets

```text
Use defold-development to investigate why the player input stops after a scene
transition. Follow the existing input and collection lifecycle, fix the cause,
and verify with the available Defold tooling.
```

```text
Use local-image-ai to discover current models and presets. Generate a low-poly
kart concept sheet with a readable silhouette and export the finished image
into the project's asset directory. Use the local service for generation.
```

```text
Use lowpoly-reference-to-blender to build a game asset from the supplied concept.
Inspect the existing Blender scene first and follow the reference and export
gates. Use the Private Blender connection.
```

The Private Blender MCP is separate from Blender-related skills. Removing the
old bundled Blender skills did not remove the MCP. Never expose that connection
to Working. Audio generation through `game-audio-sound-design` also needs its own
backend; asking for the skill does not install that backend.

## 4. Use the same workflows from Kitty and Zed

### Kitty

Open a normal workspace tab, change to the checkout and start the named wrapper:

```bash
cd ~/dev/gitlab/unified-frontend
claude-working
```

Paste the skill request into the conversation. Kitty does not decide which skills
are available. It restores tab layout and directories, not running agent sessions.
After reopening Kitty, launch the agent again.

### Zed terminal

Open the repository in Zed, open its integrated terminal and launch the same
wrapper you would use in Kitty. This is the direct way to select the stack's
Working or Private environment.

The Devkit's Claude and Codex tasks launch plain `claude` and `codex`. They do not
select a named stack profile. The YOLO tasks launch `yolo-working` or
`yolo-private`, so those tasks do select a profile.

### Zed ACP agent panel

ACP agents are separate integrations. Do not assume that installing a skill for
a terminal CLI makes it available in the ACP panel, or that ACP inherits your
shell wrapper's profile, credentials and MCP overlay. Check the integration's
actual capability list. For a workflow that depends on these stack wrappers,
use a named launcher in the Zed terminal.

## 5. Understand precedence and installation paths

The managed fallback order is:

```text
workspace/repository skill > profile package skill > shared package skill
```

The resolver recognizes immediate skill directories under `.claude/skills`,
`.codex/skills`, `.agents/skills`, `.agent/skills` and `.github/skills`, searching
from the working directory toward the repository root. Recognition by the
resolver suppresses a conflicting package fallback; it does not guarantee that
every client natively loads every one of those directories.

Existing user-owned target entries are preserved. The resolver reports conflicting workspace definitions for review. Inspect the actual
skill name in frontmatter as well as its directory name.

| Location | Purpose |
|---|---|
| `~/.local/share/frontend-ai-stack/skills/{shared,private,working,omp}/` | Default canonical stack-owned skill directories |
| `~/.codex/skills/` | Private Codex managed links alongside independent user skills |
| `~/.local/share/frontend-ai-stack/codex-working-home/skills/` | Default Working Codex skill links |
| `~/.claude/skills/` | Claude managed links alongside user-owned entries |
| `~/.omp/profiles/<profile>/agent/skills/` | OMP named-profile skills |

`MM_STACK_DATA_HOME`, `XDG_DATA_HOME`, `MM_CODEX_WORKING_HOME` and `CODEX_HOME` can
affect the relevant paths. Prefer wrappers over manually recreating their
environment. Claude's managed link destination is shared at `~/.claude/skills`;
avoid treating it as two independent profile stores or switching it underneath
a running session.

For a read-only resolver preview, run from the target project:

```bash
mm-profile-skills-sync claude private --dry-run
mm-profile-skills-sync omp working --dry-run
```

For Codex, the resolver uses `CODEX_HOME`, defaulting to `~/.codex`; its profile
argument alone does not choose the Working home. Use `codex-working` to prepare
the actual Working environment. Do not run a bare `mm-profile-skills-sync codex
working` and assume it targets the Working directory.

## 6. Share a checkpoint through TinyContext

Within the same profile and Git repository, the clients share curated TinyContext
project memory. Linked Git worktrees resolve to the same project store. Working
and Private use different stores.

Before deliberately switching clients, ask:

```text
Use project-memory to save a concise checkpoint with the completed work,
unresolved issue, relevant paths and next suggested action. Exclude secrets,
full transcripts and transient logs.
```

Start the other client in the same repository and profile, then ask:

```text
Use project-memory to recall the latest checkpoint relevant to this task.
Verify it against the current files and Git status before continuing.
```

This is a user-directed handoff, not automatic agent delegation or conversation
synchronization. To inspect the configured memory wiring:

```bash
MM_AGENT_PROFILE=private mm-project-memory-doctor
MM_AGENT_PROFILE=working mm-project-memory-doctor
```

## 7. Refresh skills and diagnose problems

Refresh this checkout's bundled payload from the package directory:

```bash
cd ~/dev/github/dev-setup/frontend-ai-optimized-stack
./install-profiles.sh --skills-only
```

Refresh optional Vercel Working skills separately:

```bash
./install-working-upstream-skills.sh --only vercel
# The installed maintenance command for the same update lane:
mm-stack-update --skills
```

These are alternative entry points for that lane; there is no need to run both.
Upstream commit records and previous directories are retained in the canonical
stack's `upstream/` directory. This does not refresh every separately installed
skill. Use the owning collection or plugin's maintenance procedure for those.

Restart the client after installation or profile-rule changes, then check:

```bash
mm-skill-audit --profile both --plugins --strict
```

| Symptom | What to check |
|---|---|
| “Skill not found” | Is it bundled, separately installed or plugin-provided? Does this client/profile list it? Restart after changes. |
| Wrong version selected | Preview precedence from the project directory; inspect workspace definitions and preserved user-owned entries. |
| Skill exists but tool is missing | Check the service, CLI, MCP registration and credentials separately. |
| ACP differs from terminal | Inspect ACP capabilities; use a named wrapper in Zed's terminal for the managed stack workflow. |
| Memory missing after switching clients | Check repository path, selected profile and `mm-project-memory-doctor`. |
| Audit reports managed drift | Compare against this checkout; refresh the intended payload instead of overwriting unrelated user skills. |
| Blender appears in Working | Stop that workflow and run `verify-profiles.sh`; inspect project-controlled MCP additions as well. |

A good task request names only the skills it needs, gives the agent a concrete
outcome, and asks for evidence appropriate to the change. Tool installation,
service availability and task verification remain separate checks.

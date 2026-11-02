# 02 · Assigning repositories

The separation works via `includeIf "gitdir:~/dev/github/"` and `includeIf "gitdir:~/dev/gitlab/"`. Keep the directory structure consistent. The names/emails in use are maintained in the private local `.gitconfig-*` files.

## Unified Frontend (GitLab.com)

Your actual repository:

- Web: https://gitlab.com/ndrde/code/unified-sophora/frontend/unified-frontend
- SSH: `git@gitlab.com:ndrde/code/unified-sophora/frontend/unified-frontend.git`

```bash
mkdir -p ~/dev/gitlab
git clone git@gitlab.com:ndrde/code/unified-sophora/frontend/unified-frontend.git \
  ~/dev/gitlab/unified-frontend

cd ~/dev/gitlab/unified-frontend
git remote -v
git config --show-origin --get user.email
git config --show-origin --get user.signingkey
git config --get commit.gpgsign
```

**If the target folder already exists**, do not clone and do not overwrite! Instead:

```bash
cd ~/dev/gitlab/unified-frontend
git status
git remote -v
```

If `origin` uses HTTPS instead of SSH, and the remote **actually** is this project:

```bash
git remote set-url origin git@gitlab.com:ndrde/code/unified-sophora/frontend/unified-frontend.git
```

## Private GitHub

```bash
mkdir -p ~/dev/github
# Use your own URL:
git clone git@github.com:OWNER/REPO.git ~/dev/github/REPO
cd ~/dev/github/REPO
git config user.email
git config user.signingkey
```

## Check before every first commit

```bash
git config --show-origin --get user.name
git config --show-origin --get user.email
git config --show-origin --get user.signingkey
git config --get commit.gpgsign
git remote -v
```

Commits from Claude Code, Codex, or Zed normally go through the same Git configuration. If a tool uses environment variables (`GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_EMAIL`), `-c user.*`, its own worktrees, or isolated HOME directories, it can bypass the path rules. Check once in the concrete tool workflow.

## Moving existing repositories to a new location

Only with a clean status and after checking the remote; mind local branches, worktrees, uncommitted changes, and script paths. Back up first. Re-creating via clone is often simpler, **if** there are no uncommitted or unsaved local data.

## Checking a local commit

```bash
git log -1 --show-signature
```

For the 'Verified' display on GitHub/GitLab, the matching public signing key must be registered. The local `allowed_signers` file only verifies your own keys listed here — it is not trust in all colleagues or team members.

# Dotfiles

Unified personal + work dotfiles managed with [chezmoi](https://www.chezmoi.io).
One repo covers both a personal Linux machine and a work macOS machine.

## Overview

Files are stored using chezmoi's naming convention — a leading `dot_` becomes a
leading `.` when applied to `$HOME` (e.g. `dot_gitconfig` becomes `~/.gitconfig`,
`dot_config/nvim/` becomes `~/.config/nvim/`). Files ending in `.tmpl` are Go
templates rendered per-machine at `chezmoi apply` time.

## Profiles vs OS — the two axes

Two independent variables drive what gets applied on any given machine:

| Axis | Values | Governs |
|---|---|---|
| `.profile` | `personal` / `work` | Identity & access: MCP servers, model provider defaults, git identity, SSH hosts, 1Password vaults, credentials |
| `.chezmoi.os` | `darwin` / `linux` / `android` (built-in) | OS mechanics: package manager, notification tooling, path conventions |

`.profile` is **not** inferred from OS — it's prompted once per machine on
`chezmoi init` and cached in `~/.config/chezmoi/chezmoi.toml`. This matters because
OS and profile happen to correlate today (work = macOS, personal = Linux/Android)
but aren't the same thing — a future personal Mac or a work Linux box should still
resolve identity/access correctly.

Templates check `.profile` first, then `.chezmoi.os` where OS mechanics differ
within a profile. `android` is chezmoi's built-in value for Termux — no extra
prompted variable needed. Package inclusion is gated in `.chezmoiignore`:

| Package | Gated by | Reason |
|---|---|---|
| `dot_aws`, `dot_config/powershell`, `dot_ssh/1Password` | `profile == work` | AWS SSO, PowerShell, corporate 1Password SSH config |
| `dot_config/1Password` | `profile == personal` | Home-lab SSH key routing rules |
| `dot_colima`, `Library/**` (macOS VS Code) | `chezmoi.os == darwin` | Mac-only tooling — applies to any Mac, personal or work |
| `dot_config/VSCodium`, `dot_vscode-oss` | `chezmoi.os == linux` | Code-OSS/VSCodium, Linux-only |
| `dot_pi`, `dot_config/opencode`, `dot_config/1Password`, `dot_config/VSCodium`, `dot_vscode-oss`, `dot_config/ghostty`, `dot_config/systemd`, `dot_docker` | `chezmoi.os == android` | Termux/phone has no AI agent apps, 1Password app, VSCodium, ghostty (client-side terminal, irrelevant over SSH), systemd, or Docker |
| `dot_docker` | *(none — common to both, except android)* | Docker CLI config used on both profiles' desktop machines |

Heavily-diverged files (`dot_config/aliases`, `dot_bashrc`, `dot_zshrc`,
`dot_config/tmux/tmux.conf`) are templated as **whole-file profile branches**
(`{{ if eq .profile "work" }}...{{ else }}...{{ end }}`) rather than
line-by-line merges — these files differ in dozens of small ways throughout
(clipboard tool, terraform vs opentofu, credential vaults), so a full-content
branch is far more maintainable than scattering conditionals everywhere.

## Repo / remotes

Three remotes, one repo, kept in sync on every push:

- `personal` — GitLab (`gitlab.com:loganmancuso_personal/dotfiles`), primary.
- `work` — GitHub (`github.com:loganmancuso-scout/dotfiles`), work machine.
  Lets the work machine `chezmoi init` straight from GitHub without needing
  GitLab credentials.
- `personal-github` — GitHub (`github.com:loganmancuso/dotfiles`), personal
  mirror on the personal GitHub account.

A local-only git alias (`pushall`, defined in `.git/config`, not tracked in
the repo) pushes the current branch to every configured remote in one shot:

```bash
git pushall
```

It's just a loop over `git remote` — add or remove a remote and `pushall`
picks it up automatically. Because it lives in local config, it must be
re-added on each new clone/machine:

```bash
git config --local alias.pushall '!f() { branch=$(git symbolic-ref --short HEAD); for r in $(git remote); do echo "--> pushing $branch to $r"; git push "$r" "$branch" || exit 1; done; }; f'
```

## Install (new machine)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
chezmoi init --apply git@gitlab.com:loganmancuso_personal/dotfiles.git
# (or from GitHub on the work machine)
chezmoi init --apply git@github.com:loganmancuso-scout/dotfiles.git
```

You'll be prompted once for `profile` (`personal` or `work`) — this is cached
locally and not asked again.

## Day-to-day

```bash
chezmoi diff      # preview what would change
chezmoi apply     # apply source -> $HOME
chezmoi re-add    # pull local $HOME changes back into the source repo
chezmoi cd        # cd into the source dir (this repo)
```

> **Habit to build:** unlike the old Stow `--adopt` setup, `chezmoi apply` copies
> files into `$HOME` rather than symlinking — so an app that mutates its own
> config live (e.g. `pi`/`opencode` settings.json theme/changelog fields) won't
> automatically flow back into the repo. Run `chezmoi re-add <path>` periodically
> to pull that drift back in before it's lost.

## OpenCode / Pi agent config

Both `opencode` and `pi` share the same instruction set, skills, and knowledge
base protocol:

- `AGENTS.md` — global session instructions
- `agents/scribe.md` — `@scribe` subagent, sole writer of KB files and READMEs
- `commands/` / `prompts/` — `/commit`, `/init-project`, `/summarize-issue`, `/closeout`
- `skills/` — `caveman`, `debug`, `docs`, `ops`, `schema`, `scribe`
- Both default to `amazon-bedrock/us.anthropic.claude-sonnet-5`, with
  `github-copilot` registered as an available fallback provider on both profiles
- `profile == personal` additionally registers a local Ollama provider
- `profile == work` additionally enables the Atlassian MCP server

### Knowledge Base

Two-layer knowledge system, shared path across both profiles:

- **`<project-root>/README.md`** — human-facing. Deployment steps, known issues, tasks.
- **`~/Documents/Notes/knowledge-base/projects/<project-name>/context.md`** —
  AI-facing institutional memory. Read silently at session start, updated via `@scribe`.
- `~/Documents/Notes/knowledge-base/bin/kb-link.sh` — appends a wikilink to the
  current week's notepad after any KB write (ported from the work machine).

Run `/init-project` when starting work on a new project.

---

## Systemd Services (Linux only)

`dot_config/systemd/user/` — gated to `chezmoi.os == linux`.

| Unit | Description |
|---|---|
| `backup.service` | Runs `restic-backup.sh` — backs up configured vaults to the USB drive |
| `backup.timer` | Fires `backup.service` every 4 hours; `Persistent=true` catches missed runs on wake |

After `chezmoi apply`, reload and enable the timer:

```bash
systemctl --user daemon-reload
systemctl --user enable --now backup.timer
```

> The service has `ConditionPathIsMountPoint=/media/%u/1TB` — it exits cleanly
> with no error if the USB drive is not plugged in. The timer will retry at the
> next scheduled interval.

### Verifying backup health

```bash
systemctl --user status backup.timer          # active? next fire time?
systemctl --user list-timers backup.timer      # all upcoming fire times
systemctl --user status backup.service         # did the last run succeed?
journalctl --user -u backup.service -n 100     # full log from last run
journalctl --user -u backup.service -f         # stream live output
systemctl --user start backup.service          # trigger a manual run
```

---

## Known Issues

### OpenCode — `edit` permission path rules not evaluated

File edit permissions configured via `permission.edit` path patterns (e.g. `~/SourceControl/**": "allow"`)
do not work — edits still prompt regardless of config. This is a confirmed upstream OpenCode bug.

**Workaround:** When prompted, approve with "always" to whitelist the pattern for the rest of the session.

**Upstream issues:**
- [#13872](https://github.com/anomalyco/opencode/issues/13872) — Permission edit patterns not working
- [#16331](https://github.com/anomalyco/opencode/issues/16331) — Permissions ignored
- [#5395](https://github.com/anomalyco/opencode/issues/5395) — Split `external_directory` into read vs write (root cause feature gap)

### `chezmoi apply` copies, doesn't symlink

See "Day-to-day" above — app-driven config drift needs a manual `chezmoi re-add`.

---

## Prerequisites

### Required (both profiles)

```bash
# chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Git LFS
git lfs install

# Neovim, tmux, fzf, starship, 1Password + CLI, Ghostty — see each tool's install docs
```

### Linux (personal) extras

```bash
sudo apt install zsh eza bat fzf tmux
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

`tpm` and the `catppuccin` theme are fetched automatically by chezmoi externals
(see `.chezmoiexternal.toml`) on `chezmoi apply` — no manual clone needed. After
applying, open tmux and press `prefix + I` once to let TPM install the
remaining declared plugins (tmux-sensible, resurrect, continuum, battery, cpu).

### macOS (work) extras

```bash
brew install eza bat fzf tmux colima docker awscli
```

### Android/Termux (personal) extras

```bash
pkg update && pkg upgrade
pkg install chezmoi git zsh tmux neovim fzf starship openssh
```

`chezmoi.os` resolves to `android` automatically under Termux — no extra
prompt needed. `pi`, `opencode`, 1Password, VSCodium, ghostty, systemd, and
Docker are all excluded on this OS value (see "Profiles vs OS" above). SSH
auth falls back to a plain `ssh-agent`/key files instead of the 1Password
agent socket, since 1Password isn't installed on the phone.

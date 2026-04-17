# Dotfiles

Personal workstation dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

Each top-level directory is a **stow package**. Files prefixed with `dot-` are
symlinked into `$HOME` with a leading `.` (e.g. `git/dot-gitconfig` becomes
`~/.gitconfig`). A shared `aliases` file is sourced by both Bash and Zsh to keep
environment variables, aliases, and shell functions in a single place.

## Packages

| Package    | Description                                          | Target                              |
|------------|------------------------------------------------------|-------------------------------------|
| `aliases`  | Shared aliases, functions, and environment variables | `~/.config/aliases`                 |
| `bash`     | Bash shell configuration                             | `~/.bashrc`                         |
| `ghostty`  | Ghostty terminal — Catppuccin Mocha, SauceCodePro NFM| `~/.config/ghostty/`                |
| `git`      | Git config — SSH commit signing via 1Password        | `~/.gitconfig`                      |
| `nvim`     | Neovim with LazyVim distribution                     | `~/.config/nvim/`                   |
| `opencode` | OpenCode AI coding assistant config                  | `~/.config/opencode/`               |
| `ssh`      | SSH hosts, 1Password agent, allowed signers          | `~/.ssh/`                           |
| `starship` | Starship cross-shell prompt — Catppuccin Mocha       | `~/.config/starship.toml`           |
| `systemd`  | User-level systemd services                          | `~/.config/systemd/user/`           |
| `tmux`     | Tmux with TPM + Catppuccin theme                     | `~/.config/tmux/`                   |
| `vscode`   | VSCodium settings and extensions                     | `~/.config/VSCodium/` `~/.vscode-oss/` |
| `zed`      | Zed editor configuration                             | `~/.config/zed/`                    |
| `zsh`      | Zsh shell config with autosuggestions                | `~/.zshrc` `~/.config/zsh/`         |

## OpenCode

The `opencode` package is a full AI coding assistant configuration built on
[OpenCode](https://opencode.ai). It includes a global agent instruction file,
custom subagents, slash commands, loadable skills, and a two-layer knowledge
base protocol that persists context across sessions.

### Agents

Custom subagents defined in `agents/`:

| Agent | Invoke | Role |
|---|---|---|
| `@scribe` | `@scribe` or task tool | Records decisions, session findings, ADRs, and README updates into the knowledge base. Cannot write source code. |

### Commands

Slash commands defined in `commands/`:

| Command | Description |
|---|---|
| `/commit` | Reviews staged changes, generates a Conventional Commit message, and commits |
| `/init-project` | Bootstraps the knowledge base for the current project |
| `/summarize-issue` | Summarizes a GitHub issue |

### Skills

Loadable skills defined in `skills/`:

| Skill | Load when |
|---|---|
| `ops` | Executing infrastructure — kubectl, Helm, Docker, OpenTofu command reference |
| `debug` | Something is broken — systematic triage and diagnosis across any system type |
| `docs` | Writing inline comments, JSDoc, READMEs, or changelogs |
| `knowledge-base` | Reading or writing project knowledge files |
| `caveman` | Compressed token-efficient responses (~75% reduction) |

### Knowledge Base

OpenCode maintains a two-layer knowledge system for each project it works on:

- **`<project-root>/README.md`** — human-facing. Deployment steps, known issues, tasks.
- **`~/Documents/Notes/projects/<project-name>/context.md`** — AI-facing institutional
  memory. Architecture, patterns, gotchas, decisions, and a session log. Read silently
  at session start and updated via `@scribe`.

Run `/init-project` when starting work on a new project to bootstrap both files from
the templates in `~/Documents/Notes/templates/`.

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

---

## Prerequisites

### Required

```bash
# GNU Stow (dotfile manager)
sudo apt install stow

# Zsh
sudo apt install zsh

# Neovim
sudo apt install neovim

# Git LFS
sudo apt install git-lfs && git lfs install
```

### CLI Tools

```bash
# Starship prompt
curl -sS https://starship.rs/install.sh | sh

# zoxide (smart cd)
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# fzf (fuzzy finder)
sudo apt install fzf

# eza (modern ls)
sudo apt install eza

# bat (modern cat)
sudo apt install bat
```

### Applications

```bash
# Ghostty — see https://ghostty.org/docs/install
# 1Password + CLI — see https://developer.1password.com/docs/cli/get-started

# Tmux
sudo apt install tmux

# TPM (Tmux Plugin Manager)
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Catppuccin theme (loaded manually, not via TPM)
git clone https://github.com/catppuccin/tmux ~/.config/tmux/plugins/catppuccin

# Then open tmux and press prefix + I to install remaining plugins
```

## Install

```bash
git clone git@gitlab.com:loganmancuso_personal/dotfiles.git $HOME/SourceControl/Personal/dotfiles
pushd $HOME/SourceControl/Personal/dotfiles
./stow-dotfiles.sh --stow
git reset --hard
popd
```

## Uninstall

```bash
pushd $HOME/SourceControl/Personal/dotfiles
./stow-dotfiles.sh --unstow
popd
```

## How It Works

The `stow-dotfiles.sh` script discovers every top-level directory (excluding
`.git`) and runs:

```bash
stow -v --dotfiles --adopt --target="$HOME" <package>
```

- **`--dotfiles`** translates `dot-` prefixes to `.` in the symlink target
- **`--adopt`** moves any existing files in `$HOME` into the repo, replacing
  them with symlinks. Run `git reset --hard` immediately after to restore the
  canonical versions from the repository.


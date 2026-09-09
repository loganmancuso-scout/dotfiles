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
| `dot_pi`, `dot_config/1Password`, `dot_config/VSCodium`, `dot_vscode-oss`, `dot_config/ghostty`, `dot_config/systemd`, `dot_docker` | `chezmoi.os == android` | Termux/phone has no AI agent apps, 1Password app, VSCodium, ghostty (client-side terminal, irrelevant over SSH), systemd, or Docker |
| `dot_termux` | `chezmoi.os == android` | Termux terminal app settings (Catppuccin Latte color scheme) — meaningless on desktop OSes, excluded everywhere else |
| `dot_docker` | *(none — common to both, except android)* | Docker CLI config used on both profiles' desktop machines |

Three files switch their Catppuccin **flavor** (not just gating whether
they apply at all) based on `chezmoi.os`: `dot_termux/colors.properties`,
`dot_config/starship.toml.tmpl`, and `dot_config/tmux/tmux.conf.tmpl` all
use Mocha (dark) normally and Latte (light) when `chezmoi.os == "android"`
— see "Terminal color scheme (light background)" under Android/Termux
extras below for why all three need to move together.

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

## SSH key material

`dot_ssh/authorized_keys` is the only file in `dot_ssh/` that's an actual
public key listing, and it's intentionally **unconditional** — no profile or
OS gating — so the same two keys (`personal_ed`, scout work key) authorize
login on every device: work, personal, mac, linux, android.

Everything else key-related (`personal_ed.priv`, `shared_ed.priv`, and any
future `id_ed25519`/`id_rsa`/`*.pem`/`*.pub` file) is a **local secret that
chezmoi never manages** — it's placed directly in `~/.ssh` per-machine, never
added to this repo. Both `.gitignore` and `.chezmoiignore` block those
patterns under `dot_ssh/**` / `.ssh/*` as a guardrail, so an accidental
`chezmoi add`/`chezmoi re-add` from `~/.ssh` can't leak private (or even
just bare public) key material into source control or get applied to a
different machine.

On `darwin`/`linux`, SSH auth and git commit signing go through the
1Password SSH agent (`IdentityAgent` / `gpg.ssh.program`). On `android`,
where there's no 1Password app, both fall back to the local key files
directly — `IdentityFile` entries in `dot_ssh/config.tmpl` for auth, and
`gpg.ssh.program = "ssh-keygen"` with `user.signingkey` pointed at
`~/.ssh/shared_ed.priv` in `dot_gitconfig.tmpl` for commit signing. Neither
needs an `ssh-agent` running — `ssh-keygen` and `ssh` both read the private
key file directly.

## Day-to-day

```bash
chezmoi diff      # preview what would change
chezmoi apply     # apply source -> $HOME
chezmoi re-add    # pull local $HOME changes back into the source repo
chezmoi cd        # cd into the source dir (this repo)
```

> **Habit to build:** unlike the old Stow `--adopt` setup, `chezmoi apply` copies
> files into `$HOME` rather than symlinking — so an app that mutates its own
> config live (e.g. `pi`'s settings.json theme/changelog fields) won't
> automatically flow back into the repo. Run `chezmoi re-add <path>` periodically
> to pull that drift back in before it's lost.

## Pi agent config

`dot_pi/agent/` holds the full Pi configuration: instruction set, skills, and
knowledge base protocol.

- `AGENTS.md` — global session instructions
- `agents/` — `scout`/`researcher`/`worker` subagents (see Pi extensions below)
- `prompts/` — `/commit`, `/init-project`, `/summarize-issue`, `/closeout`
- `skills/` — `analyze-sessions`, `caveman`, `debug`, `docs`, `ops`, `pdf-reader`,
  `schema`, `scribe`, `youtube-transcript`
- Defaults to `amazon-bedrock/us.anthropic.claude-sonnet-5`, `defaultThinkingLevel:
  "medium"` (same on both profiles), with `github-copilot` registered as an
  available fallback provider on both profiles
- `profile == personal` additionally registers a local Ollama provider
  (`dot_pi/agent/models.json`)
- `enabledModels` in `settings.json.tmpl` is a curated **favorites** list —
  it's not a hard filter: models on the list show first in `/model` and
  Ctrl+P cycling, and pressing **Tab** in `/model` switches to browsing the
  full catalog. The current list was built by live-testing every Bedrock
  (99 candidates) and Copilot (10 candidates) model with a real API call to
  confirm which respond — several Bedrock IDs fail outright (unprefixed
  `anthropic.*`/`openai.*` IDs lack on-demand throughput; `us.anthropic.claude-haiku-4-5`,
  `-opus-4-1`, and `-opus-5` need an AWS Marketplace subscription this
  account doesn't have; Meta Llama models are region/EULA-blocked).
- `packages: ["npm:pi-mcp-adapter", "npm:pi-sessions"]` — `pi-mcp-adapter`
  bridges MCP servers (see below); `pi-sessions` provides the auto-title,
  global session search/ask (`session_search`/`session_ask`), the `Alt+O`
  session picker, and the `/handoff` subagent board. Requires Node 24+ for
  `node:sqlite` FTS5 (tested working on Node 26 despite the package's
  stated `<26` ceiling).
- Global session **resume** (any session, any originating directory, from
  anywhere) is `pi -r` / `pi --resume` — this is Pi's own built-in picker
  (Tab toggles current-directory-only vs. all-sessions scope); it already
  auto-switches to the session's original working directory, so no wrapper
  script is needed.
- Both profiles configure the **1Password MCP server** (`dot_pi/agent/mcp.json.tmpl`
  → `1password`): `1password-mcp`, a local stdio server bundled with the
  1Password desktop app (`Settings > Labs > MCP Server`), scoped to
  Environments management only (list/create Environments, list/append
  variable names, local `.env` mounts) — it never returns secret values, and
  access is approved interactively via the desktop app's biometric prompt.
  No config or secrets required.
- `profile == work` additionally installs `pi-mcp-adapter` and configures work
  MCP servers (`dot_pi/agent/mcp.json.tmpl`): GitHub, Jira/Confluence, AWS
  (multi-account via `mcp-proxy-for-aws`), Microsoft WorkIQ (M365 Copilot
  Q&A grounding — read-only, no direct Graph write actions), Nutanix
  (`jkmills/nutanix-mcp-server`, pinned commit, Scout's internal Prism
  Central — one-time local install via
  `dot_pi/agent/scripts/executable_install-nutanix-mcp.sh.tmpl`, see below),
  and Juniper Mist Cloud. No secrets are stored in the template — auth
  resolves live via `gh auth token`, 1Password CLI (`op read`), or OAuth
  cached in the OS keychain.

### Nutanix MCP server — one-time local install required

Unlike the other work MCP servers (which run via `npx`/`uvx` and fetch their
package on first use), `nutanix` (`jkmills/nutanix-mcp-server`) is pinned to a
specific commit and vendored as a local git clone + Python venv, since it has
no published package. After `chezmoi apply`, run once:

```bash
~/.pi/agent/scripts/install-nutanix-mcp.sh
```

This clones the repo to `~/.pi/mcp/nutanix-mcp-server`, checks out the pinned
commit, and `pip install -e .`s it into a local venv. Re-run it any time the
pinned commit in the script is bumped. Credentials resolve live via 1Password
CLI (`op read op://<Employee vault>/Nutanix Prism Central/...`) — nothing is
stored in the template.

### Pi extensions (both profiles)

Not profile-gated — available on `work` and `personal` alike
(source: [amosblomqvist/pi-config](https://github.com/amosblomqvist/pi-config)
unless noted otherwise, ported to the `@earendil-works/*` package scope):

| Extension | Purpose |
|---|---|
| `extensions/ask-user-question.ts` | Gives the agent a real UI popup (single/multi-select or free text) to ask clarifying questions instead of guessing |
| `extensions/web-fetch/` | `web_fetch` tool: URL → clean markdown via Readability + Turndown, handles PDFs, falls back to Jina Reader for JS-rendered pages |
| `extensions/prompt-snippets/` | Small reusable behavior-rule snippets (`snippets/*.md`) toggled onto the next outgoing message, auto-reset after send |
| `extensions/custom-header.ts` | Cosmetic — replaces the startup banner with a large capital Π header |
| `extensions/browser/` | Playwright-driven headless Chromium tool (navigate, eval JS, inspect console/network, click, screenshot). **Off by default** — `/browser on` to enable for a session |
| `extensions/subagents/` | Async, interactive subagents in tmux panes — spawn a sub-agent, keep working, get steered the result when it finishes. Source: [amosblomqvist/pi-interactive-subagents](https://github.com/amosblomqvist/pi-interactive-subagents) (separate repo). Bundled agents `scout`/`researcher`/`worker` live in `dot_pi/agent/agents/`; their `model:` frontmatter was stripped so they inherit the session default (`amazon-bedrock`) instead of the upstream `openrouter` default we don't have configured, and `researcher`/`worker` had `web_search` dropped from their tool allowlists (we didn't adopt the `web-search` extension — Google API cost). **Requires tmux**: launch pi as `tmux new -A -s pi 'pi'` for subagent panes to work; this is opt-in per-use and doesn't change plain `pi` invocation |
| `extensions/observational-memory/` | Tiered, subprocess-backed session memory — parallel observer subprocesses distill conversation into a ledger, a deterministic compaction renders it into the compaction block, a consolidator promotes old observations into durable `.memory/<sessionId>/` topic files. Source: [amosblomqvist/pi-observational-memory](https://github.com/amosblomqvist/pi-observational-memory) (separate repo). **Off by default** (`om.enabled` gate) — `/om on` to enable, `/om:status` to inspect. **Spends real money when on**: each observer/consolidator run is its own subprocess `pi` call; remapped `models.observer`/`models.consolidator` in `settings.json.tmpl`'s `observational-memory` namespace from the upstream `openrouter` default to `amazon-bedrock/us.anthropic.claude-sonnet-5` (no `openrouter` provider configured here) |

`web-fetch` and `browser` ship with a `package.json` — after
`chezmoi apply`, install their npm dependencies once (`node_modules` isn't
tracked in git, so pi fails to load these extensions until this runs):

```sh
for ext in web-fetch browser; do
  (cd ~/.pi/agent/extensions/"$ext" && npm install)
done

# browser also needs the actual Chromium binary (playwright-core alone
# doesn't ship it):
npx --prefix ~/.pi/agent/extensions/browser playwright install chromium
```

Then `/reload` in pi. `prompt-snippets`, `custom-header.ts`, `subagents/`,
and `observational-memory/` have no npm dependencies.

### Pi skills (both profiles)

| Skill | Purpose |
|---|---|
| `skills/analyze-sessions/` | Python (stdlib only) scripts for pi's own session store: cost rollups, prompt-pattern mining, session rendering |
| `skills/pdf-reader/` | Read PDFs into context (extract/render/search) — needs a one-time venv: see `~/.pi/agent/skills/pdf-reader/SKILL.md` |
| `skills/youtube-transcript/` | Fetch a YouTube video's title and transcript as JSON — needs `brew install yt-dlp ffmpeg` (`ffmpeg` likely already present) |

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

### Microsoft WorkIQ MCP server

`@microsoft/workiq` connects successfully and registers its tools (confirmed
live, both via manual testing and normal use) — the tenant-admin-consent
blocker noted in earlier revisions of this file has been resolved. Startup
latency is inconsistent (observed 5-20+ seconds, occasionally timing out)
since it authenticates over the network on every Pi launch; the package is
pinned (`@microsoft/workiq@1.0.0` instead of `@latest`) to at least remove
the npm-registry-resolution cost from that variance. See
`auth-improvements.md` for the full startup-latency investigation.

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
prompt needed. `pi`, 1Password, VSCodium, ghostty, systemd, and
Docker are all excluded on this OS value (see "Profiles vs OS" above).

SSH auth and git commit signing use local key files under `~/.ssh` directly
(`personal_ed.priv` / `shared_ed.priv`, via `IdentityFile` and
`gpg.ssh.program = "ssh-keygen"`) instead of the 1Password agent socket,
since 1Password isn't installed on the phone. These are pre-existing local
secrets, never managed by chezmoi — see "SSH key material" above.

#### Terminal color scheme (light background)

`dot_termux/colors.properties` is chezmoi-managed and applied automatically
on every `chezmoi apply` — no manual step needed. It switches Termux from
its default dark scheme to Catppuccin **Latte** (light background, dark
text, full 16-color ANSI palette) instead of just overriding background/
foreground in isolation. `dot_config/starship.toml.tmpl` and
`dot_config/tmux/tmux.conf.tmpl` both switch from Catppuccin **Mocha**
(dark, used everywhere else) to **Latte** when `chezmoi.os == "android"`
for the same reason: Mocha's pastel accent colors are tuned to pop against
a *dark* background and read as washed-out/low-contrast against a *light*
one — this is most visible on grayscale e-ink screens, but is really a
light-vs-dark background mismatch, not an e-ink-specific problem. All three
files need to agree on light vs dark, or you get a light terminal
background with dark-theme (Mocha) prompt/status-bar colors. `chezmoi
apply` doesn't reload Termux's running settings by itself — run
`termux-reload-settings` once after the first apply (or fully close/reopen
the app) to pick up the color scheme.

#### Nerd Font glyphs (tofu boxes otherwise)

`starship.toml`, tmux's status bar, and the git-branch/duration icons all
rely on Nerd Font private-use-area glyphs. Termux's terminal app doesn't
ship one by default, so without this step those icons render as tofu boxes
(`□`). Install the same font ghostty uses on desktop (`SauceCodePro NFM`,
i.e. Sauce Code Pro Nerd Font Mono) as Termux's terminal font. This is a
manual, non-chezmoi step (unlike the color scheme above) — chezmoi doesn't
manage binary font files:

```bash
mkdir -p ~/tmp && cd ~/tmp
curl -sSfL -o SourceCodePro.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SourceCodePro.zip
unzip -o -j SourceCodePro.zip "SauceCodeProNerdFontMono-Regular.ttf" -d ~/tmp
mkdir -p ~/.termux
cp ~/tmp/SauceCodeProNerdFontMono-Regular.ttf ~/.termux/font.ttf
termux-reload-settings
rm -rf ~/tmp
```

> **`/tmp` is not writable by the Termux app user** (it belongs to a
> different Android app UID) — use `~/tmp` for scratch downloads instead,
> as above, or `curl`/`unzip` will fail with `client returned ERROR on
> write`.

> If glyphs still show as boxes after `termux-reload-settings`, fully close
> and reopen the Termux app — font changes sometimes need a fresh terminal
> view, not just a settings reload. `termux-reload-settings` requires the
> `termux-api` package (`pkg install termux-api`) if it's not already present.

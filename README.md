# Dotfiles (work)

Work-machine system configuration managed with [chezmoi](https://www.chezmoi.io).
Self-contained: a single identity/access profile (Scout Motors), templated
only for OS mechanics.

## Overview

Files are stored using chezmoi's naming convention — a leading `dot_` becomes a
leading `.` when applied to `$HOME` (e.g. `dot_gitconfig` becomes `~/.gitconfig`,
`dot_config/nvim/` becomes `~/.config/nvim/`). Files ending in `.tmpl` are Go
templates rendered per-machine at `chezmoi apply` time.

## OS templating

The only templated axis is `.chezmoi.os` (`darwin` / `linux` / `android`,
chezmoi built-ins — no prompted variable needed). The work machine runs
macOS today, but templates still branch on OS mechanics (package manager,
notification tooling, path conventions, SSH agent socket, git signing
program) so the repo would still resolve correctly if a future work machine
ran Linux or Termux. Package inclusion is gated in `.chezmoiignore`:

| Package | Gated by | Reason |
|---|---|---|
| `dot_colima`, `Library/**` (macOS VS Code) | `chezmoi.os == darwin` | Mac-only tooling |
| `dot_config/VSCodium`, `dot_vscode-oss` | `chezmoi.os == linux` | Code-OSS/VSCodium, Linux-only |
| `dot_pi`, `dot_config/VSCodium`, `dot_vscode-oss`, `dot_config/ghostty`, `dot_config/systemd`, `dot_docker` | `chezmoi.os == android` | Termux/phone has no AI agent apps, VSCodium, ghostty (client-side terminal, irrelevant over SSH), systemd, or Docker |
| `dot_termux` | `chezmoi.os == android` | Termux terminal app settings |
| `dot_docker` | *(none — common to all non-Android OSes)* | Docker CLI config |

`dot_config/tmux/tmux.conf.tmpl` switches its Catppuccin **flavor** (Mocha
dark / Latte light) based on `chezmoi.os == "android"` — see
`dot_config/starship.toml.tmpl` for the same pattern applied to the prompt
theme.

Heavily OS-divergent files (`dot_config/aliases`, `dot_bashrc`, `dot_zshrc`)
carry a small Linux-only block near the top (gnome-keyring `SSH_AUTH_SOCK`
workaround) but are otherwise plain, untemplated content — no whole-file
branching is needed since this repo targets one identity profile.

## Repo / remotes

One remote:

- `work` — GitHub (`github.com:loganmancuso-scout/dotfiles`).

## Install (new machine)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
chezmoi init --apply git@github.com:loganmancuso-scout/dotfiles.git
```

This clones into chezmoi's default source directory, `~/.local/share/chezmoi`
— no `sourceDir` override needed in `~/.config/chezmoi/chezmoi.toml`.

## SSH key material

Every entry under `private_dot_ssh/` carries chezmoi's `private_` attribute, on
both the directory and each file, so `~/.ssh` renders `0700` and its contents
`0600` regardless of the ambient umask. This is load-bearing, not cosmetic:
`sshd` runs `StrictModes yes` and refuses to read `authorized_keys` from a
group-writable file *or parent directory*. Without the attribute a `0002`
umask renders `~/.ssh` at `0775`, and public-key auth fails with a misleading
`Permission denied (publickey)`. **Any new file added here needs the
`private_` prefix** — the directory attribute alone does not cover contained
files.

`private_dot_ssh/private_authorized_keys` is an unconditional public-key
listing — no OS gating — so the same key authorizes login on every device
this repo is applied to.

`private_dot_ssh/private_1Password/private_config` is corporate 1Password's
own auto-generated SSH agent config — included via `Include` in
`private_dot_ssh/private_config.tmpl`, never edited by hand (1Password
overwrites it).

`~/.ssh/known_hosts` is deliberately **not** managed. `ssh` rewrites it on
every first connection to a new host, so tracking it guaranteed permanent
drift: each `chezmoi apply` reverted host keys the machine had legitimately
learned. It's in `.chezmoiignore` along with `known_hosts.old`.

Everything else key-related (`*.priv`, `id_ed25519`/`id_rsa`/`*.pem`/`*.pub`)
is a **local secret that chezmoi never manages** — placed directly in
`~/.ssh` per-machine, never added to this repo. Both `.gitignore` and
`.chezmoiignore` block those patterns under `*dot_ssh/**` / `.ssh/*` as a
guardrail, so an accidental `chezmoi add`/`chezmoi re-add` from `~/.ssh`
can't leak key material into source control or get applied to a different
machine.

> **Note:** the `.gitignore` guards are anchored with a leading `*`
> (`*dot_ssh/**/*.priv`) so they match any chezmoi attribute prefix. After
> any rename here, re-verify with `git check-ignore -v private_dot_ssh/test.priv`.

On `darwin`/`linux`, SSH auth and git commit signing go through the
1Password SSH agent (`IdentityAgent` / `gpg.ssh.program`). On `android`,
where there's no 1Password app, both fall back to local key files directly.

## Day-to-day

```bash
chezmoi diff      # preview what would change
chezmoi apply     # apply source -> $HOME
chezmoi re-add    # pull local $HOME changes back into the source repo
chezmoi cd        # cd into the source dir (this repo)
```

> **Habit to build:** `chezmoi apply` copies files into `$HOME` rather than
> symlinking — so an app that mutates its own config live (e.g. `pi`'s
> settings.json theme/changelog fields) won't automatically flow back into
> the repo. Run `chezmoi re-add <path>` periodically to pull that drift
> back in before it's lost.

## AWS SSO

`dot_aws/config` holds every Scout Motors AWS account as a named SSO
profile, all sharing one `sso-session` (`ScoutIT`). Sign in once per
session:

```bash
aws sso login --sso-session ScoutIT
```

Then any profile in the file works without a separate login
(`aws --profile <name> ...`, or `AWS_PROFILE=<name>`). The `aws` MCP server
(`dot_pi/agent/mcp.json.tmpl`) also targets these same accounts via
`mcp-proxy-for-aws` (`AWS_MCP_PROXY_PROFILES`), so both the CLI and the AI
agent authenticate against the same SSO session.

## Pi agent config

`dot_pi/agent/` holds the full Pi configuration: instruction set, skills, and
knowledge base protocol.

- `AGENTS.md` — global session instructions
- `agents/` — `scout`/`researcher`/`worker`/`investigator` subagents (see Pi extensions below)
- `prompts/` — `/commit`, `/summarize-issue`, `/closeout`
- `skills/` — `analyze-sessions`, `caveman`, `debug`, `docs`, `ops`, `pdf-reader`,
  `schema`, `scribe`, `youtube-transcript`
- Defaults to `amazon-bedrock/us.anthropic.claude-sonnet-5`,
  `defaultThinkingLevel: "medium"`, with `github-copilot` registered as an
  available fallback provider.
- `enabledModels` in `settings.json` is a curated **favorites** list — it's
  not a hard filter: models on the list show first in `/model` and Ctrl+P
  cycling, and pressing **Tab** in `/model` switches to browsing the full
  catalog. The current list was built by live-testing every Bedrock (99
  candidates) and Copilot (10 candidates) model with a real API call to
  confirm which respond — several Bedrock IDs fail outright (unprefixed
  `anthropic.*`/`openai.*` IDs lack on-demand throughput; some models need
  an AWS Marketplace subscription this account doesn't have; Meta Llama
  models are region/EULA-blocked).
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
- Configures the full work MCP server set (`dot_pi/agent/mcp.json.tmpl`):
  `1password` (local stdio server bundled with the 1Password desktop app,
  Environments-management only, no secrets in config), `github` (bearer via
  `!gh auth token`, no static PAT), `jira` (OAuth against Atlassian's
  official remote MCP), `aws` (`mcp-proxy-for-aws` via `uvx`, multi-account
  via `AWS_MCP_PROXY_PROFILES`, see "AWS SSO" above), `workiq` (Microsoft
  WorkIQ, M365 Copilot Q&A grounding — read-only, no direct Graph write
  actions), `nutanix` (`jkmills/nutanix-mcp-server`, pinned commit, Scout's
  internal Prism Central — one-time local install via
  `dot_pi/agent/scripts/install-nutanix-mcp.sh`, see below), and `mist-cloud`
  (Juniper Mist Cloud, bearer via `op read`). No secrets are stored in the
  template — auth resolves live via `gh auth token`, 1Password CLI
  (`op read`), or OAuth cached in the OS keychain.

### Nutanix MCP server — one-time local install required

Unlike the other MCP servers (which run via `npx`/`uvx` and fetch their
package on first use), `nutanix` (`jkmills/nutanix-mcp-server`) is pinned to
a specific commit and vendored as a local git clone + Python venv, since it
has no published package. After `chezmoi apply`, run once:

```bash
~/.pi/agent/scripts/install-nutanix-mcp.sh
```

This clones the repo to `~/.pi/mcp/nutanix-mcp-server`, checks out the
pinned commit, and `pip install -e .`s it into a local venv. Re-run it any
time the pinned commit in the script is bumped. Credentials resolve live via
1Password CLI (`op read op://<Employee vault>/Nutanix Prism Central/...`) —
nothing is stored in the script or the MCP template.

### Pi extensions

Source: [amosblomqvist/pi-config](https://github.com/amosblomqvist/pi-config)
unless noted otherwise, ported to the `@earendil-works/*` package scope:

| Extension | Purpose |
|---|---|
| `extensions/ask-user-question.ts` | Gives the agent a real UI popup (single/multi-select or free text) to ask clarifying questions instead of guessing |
| `extensions/web-fetch/` | `web_fetch` tool: URL → clean markdown via Readability + Turndown, handles PDFs, falls back to Jina Reader for JS-rendered pages |
| `extensions/prompt-snippets/` | Small reusable behavior-rule snippets (`snippets/*.md`) toggled onto the next outgoing message, auto-reset after send |
| `extensions/custom-header.ts` | Cosmetic — replaces the startup banner with a large capital Π header |
| `extensions/notification.ts` | Native desktop notification (`terminal-notifier` on macOS, `notify-send` on Linux, OSC 777 escape-sequence fallback on either if the native tool isn't installed) when the agent finishes a turn and is waiting for input |
| `extensions/browser/` | Playwright-driven headless Chromium tool (navigate, eval JS, inspect console/network, click, screenshot). **Off by default** — `/browser on` to enable for a session |
| `extensions/subagents/` | Async, interactive subagents in tmux panes — spawn a sub-agent, keep working, get steered the result when it finishes. Source: [amosblomqvist/pi-interactive-subagents](https://github.com/amosblomqvist/pi-interactive-subagents) (separate repo). Bundled agents `scout`/`researcher`/`worker`/`investigator` live in `dot_pi/agent/agents/`; their `model:` frontmatter was stripped so they inherit the session default (`amazon-bedrock`) instead of the upstream `openrouter` default we don't have configured, and `researcher`/`worker` had `web_search` dropped from their tool allowlists (we didn't adopt the `web-search` extension — Google API cost). **Requires tmux**: launch pi as `tmux new -A -s pi 'pi'` for subagent panes to work; this is opt-in per-use and doesn't change plain `pi` invocation |
| `extensions/observational-memory/` | Tiered, subprocess-backed session memory — parallel observer subprocesses distill conversation into a ledger, a deterministic compaction renders it into the compaction block, a consolidator promotes old observations into durable `.memory/<sessionId>/` topic files. Source: [amosblomqvist/pi-observational-memory](https://github.com/amosblomqvist/pi-observational-memory) (separate repo). **Off by default** (`om.enabled` gate) — `/om on` to enable, `/om:status` to inspect. **Spends real money when on**: each observer/consolidator run is its own subprocess `pi` call; `models.observer`/`models.consolidator` in `settings.json`'s `observational-memory` namespace are set to `amazon-bedrock/us.anthropic.claude-sonnet-5` (no `openrouter` provider configured here) |

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

### Pi skills

| Skill | Purpose |
|---|---|
| `skills/analyze-sessions/` | Python (stdlib only) scripts for pi's own session store: cost rollups, prompt-pattern mining, session rendering |
| `skills/pdf-reader/` | Read PDFs into context (extract/render/search) — needs a one-time venv: see `~/.pi/agent/skills/pdf-reader/SKILL.md` |
| `skills/ops/` | Command reference for kubectl/Helm/Docker/Argo CD/OpenTofu ops. Auth flow assumes kubeconfigs are pre-merged into a single `~/.kube/config` with one context per environment — switch via `kubectl config use-context <context>` |
| `skills/youtube-transcript/` | Fetch a YouTube video's title and transcript as JSON — needs `brew install yt-dlp ffmpeg` (`ffmpeg` likely already present) |

### Knowledge Base

Two-layer knowledge system:

- **`<project-root>/README.md`** — human-facing. Deployment steps, known issues, tasks.
- **`~/Documents/Notes/knowledge-base/projects/<project-name>/context.md`** —
  AI-facing institutional memory. Read silently at session start, updated via `@scribe`.

Starting work on a new project auto-bootstraps the knowledge base via the `scribe` skill's documentation-mode flow (see Session Start Procedure in `AGENTS.md`).

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
live, both via manual testing and normal use). Startup latency is
inconsistent (observed 5-20+ seconds, occasionally timing out) since it
authenticates over the network on every Pi launch; the package is pinned
(`@microsoft/workiq@1.0.0` instead of `@latest`) to at least remove the
npm-registry-resolution cost from that variance.

### `chezmoi apply` copies, doesn't symlink

See "Day-to-day" above — app-driven config drift needs a manual `chezmoi re-add`.

---

## Prerequisites

### Required

```bash
# chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Git LFS
git lfs install

# Neovim, tmux, fzf, starship, 1Password + CLI, Ghostty — see each tool's install docs
```

### macOS extras

```bash
brew install eza bat fzf tmux colima docker awscli
```

`tpm` and the `catppuccin` theme are fetched automatically by chezmoi
externals (see `.chezmoiexternal.toml`) on `chezmoi apply` — no manual clone
needed. After applying, open tmux and press `prefix + I` once to let TPM
install the remaining declared plugins (tmux-sensible, resurrect, continuum,
battery, cpu).

### Linux extras (if this repo is ever applied to a Linux work machine)

```bash
sudo apt install zsh eza bat fzf tmux
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

### Android/Termux extras (if this repo is ever applied under Termux)

```bash
pkg update && pkg upgrade
pkg install chezmoi git zsh tmux neovim fzf starship openssh
```

`chezmoi.os` resolves to `android` automatically under Termux — no extra
prompt needed. `pi`, VSCodium, ghostty, systemd, and Docker are all excluded
on this OS value (see "OS templating" above). SSH auth and git commit
signing fall back to local key files under `~/.ssh` directly, since
1Password isn't installed on the phone.

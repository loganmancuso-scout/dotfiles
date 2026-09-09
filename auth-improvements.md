# Authentication Friction — Investigation and Recommendations

**Date:** 2026-09-10
**Scope:** Why Pi sessions produce repeated authentication/biometric prompts,
and why cold `pi` startup is slow (30-60s reported, up to ~20s+ measured
directly). Investigation + recommendations only — no changes to
`dot_ssh/`, 1Password app settings, or credential-handling code were made,
per explicit decision during this work.

## Root Cause Analysis

Pi's work profile connects to **7 MCP servers** in parallel at every launch
(`dot_pi/agent/mcp.json.tmpl`): `1password`, `github`, `jira`, `aws`,
`workiq`, `nutanix`, `mist-cloud`. Total startup latency is bounded by the
slowest server, not the sum — but several of them are independently slow
or prompt for auth, and a cold multi-server startup compounds the pain even
though the connections themselves run via `Promise.all` (confirmed in
`pi-mcp-adapter`'s source).

### 1. Every credential lookup that shells out to `op` is a potential biometric prompt

`mcp.json.tmpl` resolves 3 separate secrets via 1Password CLI `!op read`
interpolation:

- `nutanix.env.NUTANIX_USERNAME` — `op read op://.../username`
- `nutanix.env.NUTANIX_PASSWORD` — `op read op://.../password`
- `mist-cloud.bearerToken` — `op read op://.../password`

Each is a separate `op` CLI invocation. Whether each one triggers its own
biometric approval or reuses a short-lived unlock session depends entirely
on the 1Password **desktop app's "Unlock Duration" setting**
(`1Password > Settings > Security > Lock After`) — this is not configurable
from the CLI or from this repo. If that duration is short (or set to
"immediately"), 3 separate `op read` calls at startup can mean up to 3
separate Touch ID/Face ID prompts in the first few seconds of every `pi`
launch, on top of whatever the user already approved for SSH.

**This is the most likely single source of "repeatedly prompted for
biometric approval... throughout a single session"** — not because Pi
re-authenticates mid-session, but because a fresh Pi launch fans out
multiple *independent* first-use credential lookups at once.

### 2. SSH agent reuse is already correct — not a contributor

`dot_ssh/config.tmpl` already routes `IdentityAgent` to the 1Password SSH
agent socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
on macOS, `~/.1password/agent.sock` on Linux). This is a single persistent
socket reused across every SSH connection — there's no `SSH_AUTH_SOCK`
proliferation or per-connection re-auth happening here. If SSH itself is
prompting repeatedly, that's governed by the same 1Password "Unlock
Duration" setting as above, plus each individual SSH key's own
"Require confirmation" toggle inside the 1Password app (**not** a dotfiles
setting — it's per-item, inside 1Password's own item detail view).

### 3. `github` MCP server — no repeat-prompt risk, but depends on `gh` CLI state

`bearerToken: "!gh auth token"` shells out to the GitHub CLI, which caches
its own OAuth token in the OS keychain. This does not prompt biometrically
under normal operation. The known failure mode (already documented in the
project's `context.md` gotchas) is `gh auth token` returning an *expired*
token, requiring a one-time `gh auth refresh` — an occasional manual step,
not a per-session repeat-prompt problem.

### 4. `jira` MCP server — remote OAuth, real hang risk on refresh-token expiry

`"auth": "oauth"` against Atlassian's own remote MCP endpoint
(`https://mcp.atlassian.com/v1/mcp/authv2`). OAuth access tokens are
short-lived by design; the adapter presumably refreshes silently using a
cached refresh token most of the time. **If the refresh token itself has
expired or been revoked, the only path forward is a fresh interactive
browser OAuth flow** — which will hang the entire Pi startup (MCP connect
is awaited) until the user manually completes login in a browser tab. This
was not reproduced directly during this investigation (would have required
deliberately invalidating a live token), but is a structurally real risk
given how the adapter is wired, and is a strong candidate for the
occasional "much worse than usual" startup hang the user described,
distinct from the more consistent multi-second latency from other servers.

### 5. `workiq` MCP server — slow and inconsistent, but not an auth-prompt source

Measured directly (see `migration-summary.md` / commit `8cfcb07`): 5 to
20+ seconds, with at least one observed outright timeout at 20s. It uses
a cached account (`npx ... workiq mcp` registered 9 remote tools without
any visible interactive prompt in every test run), so this is a
**latency** problem, not a **repeated-prompt** problem — already
partially mitigated by pinning the npm version instead of `@latest`
(commit `8cfcb07`), which removes the per-launch registry-resolution tax.
The remaining variance is presumably network/A2A-protocol-handshake time
against Microsoft's endpoint, which isn't something this repo can control.

### 6. `aws` MCP server — slow, but not a repeat-prompt source

`mcp-proxy-for-aws` is configured with **26** AWS profile names via
`AWS_MCP_PROXY_PROFILES`. Measured 5-11 seconds to connect (cold `uvx`
package resolution added ~6s on a cold cache; a warm cache still took ~5s).
Whether this involves AWS SSO re-auth prompts depends on each profile's
SSO session validity — profiles with expired SSO sessions would surface as
`aws sso login` prompts rather than biometric ones, and weren't
individually tested here (would require deliberately expiring 26 SSO
sessions). The user explicitly chose not to trim this list during this
session — see `migration-summary.md`.

### 7. `1password` MCP server (both profiles) — approved by design, not a bug

`1password-mcp` is a local stdio binary bundled with the 1Password desktop
app, scoped to Environments management only. Per the project's own
`README.md`, "access is approved interactively via the desktop app's
biometric prompt" — **this one is supposed to prompt**, by 1Password's own
MCP security model (no persistent unattended access to secrets). Not a bug,
not something to "fix" without weakening the actual security boundary
1Password intentionally put there.

## Proposed Fixes

None of these are code changes — they're 1Password app / OS-level settings
outside this repo's scope, listed here as recommendations per the decision
to keep this investigation doc-only:

1. **Increase 1Password's "Unlock Duration"** (`Settings > Security > Lock
   After`) to a longer window (e.g. "1 hour" instead of "immediately" or a
   short default). This directly reduces how often *any* `op`-backed
   credential lookup re-prompts, addressing root cause #1 with the single
   highest leverage change available. Tradeoff: a longer unlock window is
   less secure if the machine is left unattended unlocked — this is a
   judgment call for the user, not something to change unilaterally.
2. **Check each SSH key's "Require confirmation" setting inside the
   1Password app** (per-item, under the key's detail view) — if set to
   "always confirm," this is independent of Unlock Duration and will
   prompt on every single SSH connection regardless. Setting it to rely on
   the app's unlock state instead (rather than per-use confirmation) is the
   1Password-native equivalent of `ControlMaster`/`ControlPersist` — it
   doesn't need an SSH `ControlMaster` config change in this repo, because
   the friction is happening one layer up, inside 1Password's own
   authorization model.
3. **Consolidate the two `nutanix` `op read` calls into one** (`op item get
   <item> --fields label=username,label=password --format json`) — this
   was investigated but **not applied**: 1Password CLI's own short-lived
   unlock-session caching (a few seconds after a biometric approval) most
   likely already coalesces back-to-back `op` calls issued within the same
   process startup into a single prompt, making this optimization probably
   redundant. Not verified interactively (this environment can't trigger
   Touch ID), so left as a documented "check before implementing"
   recommendation rather than a code change.
4. **If `jira` OAuth hangs are observed in practice**, check
   `pi-mcp-adapter`'s OAuth token cache location/expiry (not identified
   precisely during this investigation — would need a follow-up session
   specifically reproducing an expired-refresh-token scenario) and consider
   whether Atlassian's refresh-token lifetime can be extended on the
   Atlassian admin side.

## Implemented Fixes (this session)

- Pinned `workiq` from `@latest` to `1.0.0` in `dot_pi/agent/mcp.json.tmpl`
  (commit `8cfcb07`) — removes an npm-registry-resolution round-trip from
  every single Pi launch. Doesn't address the underlying A2A-handshake
  latency variance, but is a legitimate, verified, zero-downside win.

## Risks

- None of the proposed 1Password-app-level changes were applied — they
  require the user's own judgment about their security posture (a longer
  unlock duration is a real security/convenience tradeoff, not a free win).
- The `jira` OAuth hang risk (root cause #4) is diagnosed structurally but
  not reproduced or confirmed live — treat as a hypothesis, not a
  confirmed root cause, until it's actually observed and correlated with a
  slow startup.

## Validation Steps

To verify any of the above after making a 1Password setting change:

```bash
# Time a cold pi startup with full internal timing breakdown
PI_TIMING=1 pi --print --no-session -p "hi" < /dev/null
# Look at "Startup Timings: main" -> createAgentSessionRuntime,
# and watch for any biometric prompt during that window.
```

```bash
# Time each MCP server's underlying command in isolation
time npx -y @microsoft/workiq@1.0.0 mcp < /dev/null
time uvx mcp-proxy-for-aws@1.6.4 https://aws-mcp.us-east-1.api.aws/mcp < /dev/null
time op read "op://<vault>/<item>/<field>"
```

Re-run the same commands before and after adjusting 1Password's Unlock
Duration setting to confirm whether the number of biometric prompts (not
just latency) actually drops.

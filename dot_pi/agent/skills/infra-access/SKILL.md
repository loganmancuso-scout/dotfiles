---
name: infra-access
description: >
  Passwordless SSH access to infrastructure (routers, switches, PLC/plant equipment,
  Zscaler connectors, etc.) via ~/.ssh/config and the 1Password SSH agent. Load when an
  investigation or ops task needs to reach a host directly rather than through
  kubectl/helm/docker, or when unsure what hosts are reachable.
---

`~/.ssh/config` is a maintained inventory of infrastructure this machine can reach without a
password, via the 1Password SSH agent. Read it; don't guess hostnames or assume a target is
unreachable without checking it first.

---

## How the access works

```
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  IdentityAgent ~/.1password/agent.sock
  StrictHostKeyChecking no
```

Every host in the file inherits key-based auth served by 1Password (no local private key
files — `.chezmoiignore` deliberately excludes key material from being managed here).
`StrictHostKeyChecking no` means host-key prompts won't block a session.

Two `Include`s pull in additional host blocks:
- `~/.colima/ssh_config`
- `~/.ssh/1Password/config`

## Discover before you probe

```bash
grep -E '^Host ' ~/.ssh/config | sort
```

~41 hosts as of this writing — don't hardcode that number, re-check it. Entries include
Juniper MX/SRX routers, Zscaler branch connectors, and plant MDF/PLC network switches. Some
hosts carry explicit overrides (e.g. legacy `KexAlgorithms`/`HostKeyAlgorithms` for older
Junos/network gear) already encoded in the config — don't try to override these yourself,
the file has already solved that problem per-host.

## Running commands

Keep everything non-interactive and bounded, same discipline as any other ops command:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 <host> '<command>'
```

- `BatchMode=yes` fails fast instead of hanging on an unexpected prompt.
- `ConnectTimeout=5` bounds the connection attempt; pair with the bash tool's own `timeout`
  parameter for the overall command (see Timeout Policy gotcha in `AGENTS.md` — the
  `timeout` binary is not installed on this machine).
- For Juniper devices, remote commands typically need `cli -c "<command>"` rather than a
  bare shell command.

## Fan-out for multi-host investigations

Checking the same symptom across several hosts is the canonical case for dispatching one
`investigator` sub-agent per host in a single turn (see "Parallel Work & Subagent
Delegation" in `AGENTS.md`). Each investigator starts with a clean context and must read
`~/.ssh/config` itself — include the specific host name(s) it's responsible for in its task
prompt, not the whole inventory.

## What not to do

- Never write, generate, or modify SSH key material — identities are served live from
  1Password, not stored as files, and `.chezmoiignore` enforces this.
- Never touch `known_hosts` / `known_hosts.old` — they're machine-local and explicitly
  unmanaged (chezmoi would fight ssh's own rewrites).
- This is read-only recon territory by default. Any command that reconfigures a device
  (interface changes, firewall rules, firmware) is a mutating infra operation — same rule
  as `ops`: confirm with the user first, never fan out in parallel.

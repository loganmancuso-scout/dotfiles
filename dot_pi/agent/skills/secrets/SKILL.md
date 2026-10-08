---
name: secrets
description: >
  Retrieving, storing, and injecting passwords, API keys, tokens, and other credentials
  via the 1Password `op` CLI. Load whenever a task needs a password, secret, credential,
  token, API key, or vault item — before asking the user to provide one or guessing where
  it lives.
---

Credential retrieval and storage, backed by 1Password. The user should never need to paste
a secret into chat — if a task needs one, get it from 1Password first.

---

## Tool selection — read this before doing anything

Two different things are both called "1Password" in this environment. They are not
interchangeable.

| Need | Tool |
|---|---|
| Read/write a password, API key, token, or any vault item field | **`op` CLI** |
| Manage a 1Password *Environment* (`.env`-style variable sets for local dev) | `1password` MCP server |

The `1password` MCP server's tools (`1password_list_environments`,
`1password_list_variables`, `1password_create_local_env_file`, etc.) are scoped **only** to
Environments. It cannot read an arbitrary vault item. If the task is "get me the password
for X" or "store this API key," do not reach for the MCP server — use the `op` CLI directly
via `bash`.

Known environment (verified, do not re-check every session):
- Account: `scoutmotorsinc.1password.com`
- Vault: `LoganMancuso-Automation` (`wqghe4bimpx7yuizvsas4ysiwu`)
- `op` is already signed in; no `op signin` dance expected in normal use

---

## Reading secrets

Prefer the forms that never print the raw secret into the transcript:

```bash
# Inject a secret into a command's environment without ever displaying it
op run --env-file=.env.op -- <command>

# Fetch a single field by secret reference (the convention already used in
# mcp-adapter.json.tmpl: "!op read op://<vault>/<item>/<field>")
op read "op://LoganMancuso-Automation/<item-id>/password"

# List items to find the right one before reading
op item list --vault LoganMancuso-Automation
op item get <item-name-or-id> --vault LoganMancuso-Automation
```

If a value must be read directly (e.g. to pass as a CLI flag the task truly requires),
treat it as sensitive for the rest of the session: don't echo it back to the user, don't
write it to a file, don't let it land in a KB note or a script.

## Storing secrets

```bash
op item create --category=password --title "<title>" --vault LoganMancuso-Automation \
  password=<value>

op item edit <item-name-or-id> --vault LoganMancuso-Automation password=<new-value>

# Generate instead of inventing a password
op item create --category=password --title "<title>" --vault LoganMancuso-Automation \
  --generate-password
```

## The `op://` reference convention

Config files in this environment store secrets as `op://<vault>/<item>/<field>` references
resolved at load time via `!op read ...`, not as literal values. See
`dot_pi/agent/mcp-adapter.json.tmpl` for four live examples (context7, nutanix x2,
mist-cloud). Follow this pattern for any new config that needs a credential — write the
`op://` reference, never the resolved value, into the file.

## Hygiene rules — hard requirements

- **Never print a secret value into the conversation** if an injection form (`op run`,
  `op inject`, `!op read ...` in a config) will do the job instead.
- **Never write a secret to a file** — not to `/tmp`, not to the KB, not to a script, not to
  git. Reference it by `op://` URI in documentation instead of the resolved value.
- **Never ask the user to paste a password, token, or key into chat.** If `op` doesn't have
  it, say so and ask where it should be stored, rather than accepting it inline.
- **1Password also serves SSH keys** — see the `infra-access` skill for how passwordless
  SSH into infrastructure actually works. It's the same vault/agent mechanism, different
  tool.

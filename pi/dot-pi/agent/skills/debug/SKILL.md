---
name: debug
description: >
  Generic debugging methodology for any system or codebase — Java apps, K8s clusters,
  Docker Compose, scripts, APIs, or anything else. Focuses on evidence gathering,
  hypothesis testing, fix validation, and knowledge base updates.
  Load ops skill to execute infrastructure commands. Load knowledge-base for project context.
---

Something is wrong. Work systematically: gather evidence first, form a hypothesis, make one change, validate, repeat.

## Timeout Policy

Keep command timeouts low. Do not wait indefinitely — a hang is evidence, not a reason to keep waiting.

- Read-only commands (`curl`, `nc`, `kubectl get`, `docker logs`): **30s max**
- Use `curl --connect-timeout 5 --max-time 30` for all HTTP probes
- Use `nc -zv -w 5 <host> <port>` for TCP connectivity checks
- Use `kubectl logs --tail=100` rather than streaming indefinitely
- If a command hangs past 60s: kill it, record what was observed, treat the hang as a symptom

---

## Step 1 — Understand the System

Before touching anything, establish what you're working with.

Load the `knowledge-base` skill and read the project `context.md`. It may already contain relevant gotchas, runbook entries, or past decisions that explain the failure.

Then identify:
- **What kind of system is this?** (JVM app, containerized service, K8s workload, Docker Compose stack, shell script, API, CLI tool, etc.)
- **What is the expected behavior?**
- **What is the actual behavior?** (exact error, symptom, output)
- **When did it start?** (after a deploy, a config change, a dependency update, out of nowhere)
- **What changed recently?** (git log, deploy history, dependency bumps, environment changes)
- **What is the blast radius?** (one user, one service, everything)

Do not skip this step. Jumping to fixes without understanding the system wastes time and introduces new problems.

---

## Step 2 — Gather Evidence

Collect raw data before forming any hypothesis. Do not interpret yet — just collect.

### Logs
Find and read the logs for the failing component:
```bash
# Application log files
find . -name "*.log" | head -20
tail -100 <logfile>
grep -i "error\|exception\|fatal\|panic\|warn" <logfile> | tail -50

# Structured JSON logs
cat <logfile> | jq 'select(.level == "error" or .level == "fatal")'

# Journald / systemd
journalctl -u <service> -n 100 --no-pager
journalctl -u <service> --since "10 minutes ago"

# Docker
docker logs <container> --tail=100
docker logs <container> 2>&1 | grep -i "error\|exception\|fatal"

# Kubernetes
kubectl logs <pod> -n <ns> --tail=100
kubectl logs <pod> -n <ns> --previous
kubectl logs <pod> -n <ns> -c <container>
```

### Process / runtime state
```bash
ps aux | grep <process>
lsof -i :<port>                    # what's listening on a port
ss -tulpn                          # all listening sockets
netstat -tulpn
```

### Resource usage
```bash
top
free -h
df -h
du -sh <directory>
```

### Network / connectivity
```bash
curl -sv <url>                     # HTTP with full headers and timing
curl -sv --connect-timeout 5 <url>
nc -zv <host> <port>               # TCP connectivity
nslookup <hostname>
dig <hostname>
ping -c 4 <host>
traceroute <host>
```

### Configuration
Read the actual config the process is using — not what you think it should be:
```bash
cat <config-file>
env | sort                         # environment variables
<process> --version                # confirm version
<process> --help | grep config     # find config file locations
```

### Recent changes
```bash
git log --oneline -20
git diff HEAD~1
git stash list
```

---

## Step 3 — Form a Hypothesis

Based on the evidence, state a hypothesis:

> "I believe the failure is caused by X because I observed Y and Z."

Be specific. Vague hypotheses lead to vague fixes.

If multiple hypotheses are plausible, rank them by likelihood and test the most likely one first. State the full ranked list before testing anything.

---

## Step 4 — Test the Hypothesis

Design the smallest possible test that confirms or disproves the hypothesis. This is not a fix yet — it's a probe.

Examples:
- Add a log statement and re-run
- Call an endpoint directly with `curl` to isolate a layer
- Run a unit test for the specific function
- Reproduce the failure in isolation (single container, single request, single input)
- Comment out a recent change and verify the symptom disappears
- Check the config value that the hypothesis depends on

One test at a time. If the test disproves the hypothesis, go back to Step 3 with the new evidence.

---

## Step 5 — Make the Fix

Once the root cause is confirmed, make the smallest fix that addresses it. Do not refactor, clean up, or improve unrelated things in the same change.

For infrastructure changes (deploy, restart, scale, rollout): load the `ops` skill and follow its command patterns.

For code changes: edit the file, then immediately proceed to Step 6.

---

## Step 6 — Validate

Confirm the fix actually resolves the issue. Do not assume — verify.

### Functional validation
- Re-run the failing test, command, or request that reproduced the issue
- Confirm the expected output is now returned
- Check logs for absence of the original error

### Regression check
- Run the existing test suite if one exists
- Verify adjacent functionality still works
- Check that the fix doesn't introduce a new failure mode

### Infrastructure validation (if applicable)
Load the `ops` skill. For K8s:
```bash
kubectl rollout status deployment/<name> -n <ns>
kubectl get pods -n <ns>
kubectl logs -n <ns> -l app=<label> --tail=50
```
For Docker:
```bash
docker ps
docker logs <container> --tail=50
```
For Tofu/Terraform: check `tofu output` and verify the expected resource state.

---

## Step 7 — Record Findings

After resolving, invoke `@scribe` with a summary of:
- What the root cause was
- What the fix was
- Any non-obvious behavior discovered (goes into `## Gotchas & Sharp Edges`)
- Any runbook update needed (goes into `## Maintenance Runbook`)
- Whether an open question was resolved

Do not skip this step. The next debugging session on this system will benefit from it.

---

## Principles

**One change at a time.** Making multiple changes simultaneously makes it impossible to know what fixed it.

**Evidence before hypothesis.** Do not form a theory before reading the logs and checking the config.

**Reproduce before fixing.** If you cannot reproduce the failure, you cannot confirm the fix.

**Read the error message.** Fully. The answer is usually in the first line.

**Check the obvious first.** Wrong config file, wrong environment, service not running, port in use, dependency not started.

**Distinguish symptoms from causes.** A pod restarting is a symptom. OOMKilled from a memory leak is the cause. Fix the cause.

---
name: k8s-ops
description: Diagnose Kubernetes failures and remediate via Helm — covers pod triage, log analysis, helm diff, dry-run deploy, rollout verification, and rollback
compatibility: opencode
metadata:
  audience: platform-engineers
  workflow: kubernetes
---

## What I do

Guide a structured two-phase workflow: **diagnose** the failure using Kubernetes read-only commands, then **remediate** safely via Helm with dry-run gating before any live changes.

---

## Phase 1: Diagnose

### Step 1 — Establish context

Before anything else, identify the scope:

```bash
kubectl config current-context
kubectl config get-contexts
```

Ask the user to confirm the correct namespace and cluster if ambiguous.

### Step 2 — Survey pod health

```bash
kubectl get pods -n <namespace>
kubectl get pods -n <namespace> -o wide          # shows node assignment
kubectl get events -n <namespace> --sort-by=.lastTimestamp | tail -30
```

Look for these status patterns and their likely causes:

| Status | Common Cause |
|--------|-------------|
| `CrashLoopBackOff` | App crash on startup, bad config, missing secret/env |
| `OOMKilled` | Memory limit too low, memory leak |
| `ImagePullBackOff` | Bad image tag, missing registry credentials |
| `Pending` | Insufficient node resources, unschedulable (taints/tolerations) |
| `Terminating` (stuck) | Finalizer not resolving, node lost |
| `Error` | Init container failed, entrypoint crash |

### Step 3 — Inspect the failing pod

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Key sections to read in the output:
- **Events** — scheduling failures, image pull errors, liveness probe failures
- **Conditions** — `Ready`, `ContainersReady`, `PodScheduled`
- **Containers.State** — `waiting.reason`, `lastState.terminated.exitCode`
- **Resources** — compare requests vs limits; check for missing resource constraints

Exit code reference:

| Exit Code | Meaning |
|-----------|---------|
| `0` | Clean exit (unexpected for a service) |
| `1` | App error / unhandled exception |
| `137` | OOMKilled (SIGKILL) |
| `139` | Segfault |
| `143` | SIGTERM (graceful shutdown) |

### Step 4 — Read the logs

```bash
# Current logs
kubectl logs <pod-name> -n <namespace>

# Previous crash logs (most useful for CrashLoopBackOff)
kubectl logs <pod-name> -n <namespace> --previous

# Specific container in multi-container pod
kubectl logs <pod-name> -n <namespace> -c <container-name>

# Stream live logs
kubectl logs <pod-name> -n <namespace> -f --tail=100
```

Look for:
- First error after startup
- Panic / fatal messages
- Config parsing failures
- Connection refused / timeout to dependencies

### Step 5 — Inspect configuration

```bash
# Check the deployment spec
kubectl get deployment <name> -n <namespace> -o yaml

# Check ConfigMaps the pod references
kubectl get configmap <name> -n <namespace> -o yaml

# Verify secrets exist (never print values)
kubectl get secret <name> -n <namespace>
kubectl describe secret <name> -n <namespace>

# Check environment variables resolved in the pod
kubectl exec <pod-name> -n <namespace> -- env | sort
```

### Step 6 — Check resource pressure

```bash
kubectl top pods -n <namespace>
kubectl top nodes
kubectl describe node <node-name>   # check Allocatable vs Requests
```

### Step 7 — Diagnose network / DNS

```bash
# DNS resolution from inside the cluster
kubectl exec <pod-name> -n <namespace> -- nslookup <service-name>
kubectl exec <pod-name> -n <namespace> -- nslookup <service-name>.<namespace>.svc.cluster.local

# Test connectivity to a dependency
kubectl exec <pod-name> -n <namespace> -- curl -sv http://<service>:<port>/healthz

# Check service endpoints are populated
kubectl get endpoints <service-name> -n <namespace>

# Check service selector matches pod labels
kubectl get svc <service-name> -n <namespace> -o yaml
kubectl get pods -n <namespace> --show-labels
```

### Step 8 — Check Helm release state

```bash
helm list -n <namespace>
helm status <release-name> -n <namespace>
helm history <release-name> -n <namespace>

# Inspect the currently deployed values
helm get values <release-name> -n <namespace>

# Inspect the full rendered manifests
helm get manifest <release-name> -n <namespace>
```

---

## Phase 2: Remediate

Only proceed to this phase once the root cause from Phase 1 is identified.

### Step 1 — Diff the proposed change

Before touching anything live, always diff:

```bash
# If using helm diff plugin
helm diff upgrade <release-name> <chart> -n <namespace> -f values.yaml

# Without plugin, use dry-run to see rendered output
helm upgrade <release-name> <chart> -n <namespace> -f values.yaml --dry-run
```

Review the diff carefully:
- Are only expected resources changing?
- Are any Secrets or ServiceAccounts being modified unexpectedly?
- Are resource limits / replicas changing correctly?

**Do not proceed if the diff contains unexpected changes.** Surface them to the user first.

### Step 2 — Dry-run the upgrade

```bash
helm upgrade <release-name> <chart> \
  -n <namespace> \
  -f values.yaml \
  --dry-run \
  --debug
```

Confirm:
- No template rendering errors
- Resource definitions look correct
- Image tag is the intended version

### Step 3 — Apply the upgrade

```bash
helm upgrade <release-name> <chart> \
  -n <namespace> \
  -f values.yaml \
  --atomic \           # auto-rollback if rollout fails
  --timeout 5m \
  --wait
```

Prefer `--atomic` for safety. It rolls back automatically if pods don't become healthy within the timeout.

### Step 4 — Verify the rollout

```bash
kubectl rollout status deployment/<name> -n <namespace>
kubectl get pods -n <namespace> -w     # watch pods cycle
kubectl logs -n <namespace> -l app=<label> --tail=50
```

Confirm:
- All pods reach `Running` / `1/1 Ready`
- No new errors in logs post-deploy
- Liveness and readiness probes passing

### Step 5 — Rollback if needed

If the deploy introduced a regression:

```bash
# Roll back to the previous Helm revision
helm rollback <release-name> -n <namespace>

# Roll back to a specific revision
helm rollback <release-name> <revision-number> -n <namespace>

# Verify rollback
helm history <release-name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
```

---

## When to use me

Load this skill when:
- A pod is crashing, stuck, or not scheduling
- A Helm deployment is failing or needs a safe upgrade
- You need to trace a failure from symptoms to root cause
- You want structured guidance before making a live cluster change

## When NOT to use me

- For application-level code bugs (use the `debug` agent instead)
- For Terraform infrastructure changes (outside scope)
- For cluster provisioning or node management

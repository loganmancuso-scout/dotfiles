---
name: ops
description: >
  Command reference for infrastructure operations — kubectl, Helm, Docker, and OpenTofu.
  Covers the right commands, flags, and patterns for running infra efficiently and safely.
  Load when executing deployments, upgrades, scaling, or infrastructure management.
---

Command reference for infrastructure operations. No diagnosis — load `debug` for that.

---

## Authentication — Required Before Any Ops

Before running any `kubectl`, `helm`, or `tofu` command, the environment must be authenticated
**once per session**. Two alias commands handle this:

> **Important:** `kubeconfig` are shell aliases defined in `~/.config/aliases`.
> They are not available in a plain bash subshell. Always source the aliases file first:

```bash
source ~/.config/aliases
kubeconfig <environment>.config
```

Or chain in a single command:

```bash
source ~/.config/aliases kubeconfig <environment>.config
```

Once authenticated, you do not need to re-run these for subsequent commands in the same session.

**Examples:**
```bash
kubeconfig core.config
kubeconfig application.config
```

### Determining the environment

Use context clues from the working directory, project name, or task description to infer
the target environment. When ambiguous or not obvious, **ask the user** before proceeding:

> "Which environment are we targeting? (e.g. dev-core, core)"

Do not guess the environment and do not run any `kubectl`, `helm`, or `tofu` command until
auth is confirmed. A wrong environment could mutate production infrastructure.

**When switching environments mid-session**, re-run the full auth sequence for the new
environment before executing any further commands — credentials and kubeconfig from the
previous environment are not automatically cleared:

```bash
source ~/.config/aliases && kubeconfig <new-env>.config
```

Verify the switch succeeded before continuing:

```bash
kubectl config current-context
```

### Auth checklist before any ops session

- [ ] Environment identified (from context or user confirmation)
- [ ] `source ~/.config/aliases` run successfully
- [ ] `kubeconfig <env>.config` run successfully
- [ ] `kubectl config current-context` confirms correct cluster

---

## Timeout Policy

Keep command timeouts low. Default to **60s** for read-only commands, **120s** for mutating operations. Do not wait indefinitely for a command — a hang is itself a signal worth surfacing.

- `helm upgrade` / `helm install` — use `--timeout 2m` unless the workload is known to take longer
- `kubectl rollout status` — add `--timeout=120s`
- `kubectl wait` — always set `--timeout`
- `tofu apply` — if a resource is taking >2m, surface it rather than waiting silently
- `curl` — always use `--connect-timeout 5 --max-time 30` unless testing a slow endpoint
- `docker build` — no artificial timeout; image builds vary. Surface slow steps.

If a command exceeds its timeout: stop, report what was observed up to that point, and treat the hang as a symptom to investigate with `debug`.

---

## Kubernetes

### Cluster context
```bash
kubectl config current-context
kubectl config get-contexts
kubectl config use-context <context>
kubectl cluster-info
```

### Inspect resources
```bash
kubectl get pods -n <ns>
kubectl get pods -n <ns> -o wide                      # node placement
kubectl get pods -n <ns> -w                           # watch
kubectl get all -n <ns>                               # pods, svc, deploy, rs
kubectl get nodes
kubectl describe pod <pod> -n <ns>
kubectl describe deployment <name> -n <ns>
kubectl describe node <node>
kubectl top pods -n <ns>
kubectl top nodes
```

### Apply / delete
```bash
kubectl apply -f <file>
kubectl apply -f <dir>/                               # all files in directory
kubectl apply --dry-run=client -f <file>              # validate without applying
kubectl delete -f <file>
kubectl delete pod <pod> -n <ns>
kubectl delete pod <pod> -n <ns> --force --grace-period=0  # force delete stuck pod
```

### Rollouts
```bash
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout history deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>        # roll back one revision
kubectl rollout undo deployment/<name> -n <ns> --to-revision=<n>
kubectl rollout restart deployment/<name> -n <ns>     # rolling restart
```

### Scale
```bash
kubectl scale deployment/<name> -n <ns> --replicas=<n>
```

### Exec / copy
```bash
kubectl exec -it <pod> -n <ns> -- /bin/sh
kubectl exec -it <pod> -n <ns> -c <container> -- /bin/sh
kubectl cp <ns>/<pod>:/path/to/file ./local-file
kubectl port-forward <pod> <local>:<remote> -n <ns>
kubectl port-forward svc/<service> <local>:<remote> -n <ns>
```

### Logs
```bash
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl logs <pod> -n <ns> -c <container>
kubectl logs <pod> -n <ns> -f --tail=100
kubectl logs -n <ns> -l app=<label> --tail=50         # logs from all matching pods
```

### ConfigMaps / Secrets
```bash
kubectl get configmap <name> -n <ns> -o yaml
kubectl create configmap <name> --from-file=<file> -n <ns>
kubectl get secret <name> -n <ns>
kubectl create secret generic <name> --from-literal=key=value -n <ns>
```

---

## Helm

### Inspect
```bash
helm list -n <ns>
helm list -A                                          # all namespaces
helm status <release> -n <ns>
helm history <release> -n <ns>
helm get values <release> -n <ns>
helm get manifest <release> -n <ns>
helm get all <release> -n <ns>
```

### Search / show
```bash
helm search repo <chart>
helm search hub <chart>
helm show values <chart>
helm show chart <chart>
```

### Install
```bash
helm install <release> <chart> -n <ns> -f values.yaml
helm install <release> <chart> -n <ns> --create-namespace -f values.yaml
```

### Upgrade
```bash
# Always diff first if helm-diff plugin is available
helm diff upgrade <release> <chart> -n <ns> -f values.yaml

# Dry-run to preview rendered output
helm upgrade <release> <chart> -n <ns> -f values.yaml --dry-run --debug

# Apply — prefer --atomic for safety (auto-rollback on failure)
helm upgrade <release> <chart> -n <ns> -f values.yaml \
  --atomic \
  --timeout 5m \
  --wait

# Upgrade and install if not present
helm upgrade --install <release> <chart> -n <ns> -f values.yaml --atomic
```

### Rollback
```bash
helm rollback <release> -n <ns>                       # previous revision
helm rollback <release> <revision> -n <ns>            # specific revision
helm history <release> -n <ns>                        # check revisions first
```

### Uninstall
```bash
helm uninstall <release> -n <ns>
```

### Repos
```bash
helm repo add <name> <url>
helm repo update
helm repo list
```

---

## Docker

### Images
```bash
docker images
docker pull <image>:<tag>
docker build -t <image>:<tag> .
docker build -t <image>:<tag> -f <Dockerfile> .
docker push <image>:<tag>
docker rmi <image>:<tag>
docker image prune                                    # remove dangling images
```

### Containers
```bash
docker ps
docker ps -a                                          # include stopped
docker run -d --name <name> <image>:<tag>
docker run -it --rm <image>:<tag> /bin/sh             # interactive, delete on exit
docker stop <container>
docker start <container>
docker restart <container>
docker rm <container>
docker rm -f <container>                              # force remove running container
```

### Inspect / exec
```bash
docker inspect <container>
docker logs <container>
docker logs <container> -f --tail=100
docker exec -it <container> /bin/sh
docker stats <container>
docker top <container>
```

### Networking / volumes
```bash
docker network ls
docker network inspect <network>
docker volume ls
docker volume inspect <volume>
```

### Compose
```bash
docker compose up -d
docker compose down
docker compose ps
docker compose logs -f
docker compose pull
docker compose build
```

### Cleanup
```bash
docker system df                                      # disk usage summary
docker system prune                                   # remove unused resources
docker system prune -a                               # include unused images
```

---

## OpenTofu / Terraform

> Commands below use `tofu`. Substitute `terraform` if using Terraform directly.

### Init / format / validate
```bash
tofu init                                             # initialize working directory
tofu init -upgrade                                    # upgrade provider versions
tofu fmt                                              # format all .tf files
tofu fmt -check                                       # check formatting without writing
tofu validate                                         # validate configuration syntax
```

### Plan
```bash
tofu plan                                             # show what will change
tofu plan -out=tfplan                                 # save plan to file
tofu plan -refresh=false                              # skip state refresh
tofu plan -target=<resource>                          # plan a single resource
```

### Apply
```bash
tofu apply                                            # apply with confirmation prompt
tofu apply tfplan                                     # apply saved plan (no prompt)
tofu apply -target=<resource>                         # apply single resource
tofu apply -auto-approve                              # skip confirmation (use carefully)
```

### Destroy
```bash
tofu destroy                                          # destroy all resources
tofu destroy -target=<resource>                       # destroy single resource
```

### State
```bash
tofu state list                                       # list all managed resources
tofu state show <resource>                            # detail on one resource
tofu state mv <source> <dest>                         # rename resource in state
tofu state rm <resource>                              # remove from state (not real infra)
tofu import <resource> <id>                           # import existing infra into state
tofu force-unlock <lock-id>                           # release stuck state lock
```

### Outputs / workspace
```bash
tofu output                                           # show all outputs
tofu output <name>                                    # show specific output
tofu output -json                                     # machine-readable
tofu workspace list
tofu workspace show
tofu workspace select <name>
tofu workspace new <name>
```

### Providers
```bash
tofu providers
tofu providers lock                                   # lock provider versions
tofu version
```

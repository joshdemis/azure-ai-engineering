# Troubleshooting Log

A running log of real errors hit during the roadmap, written as reusable
knowledge so they are searchable later. This maps to the exam domain "Secure,
monitor, and troubleshoot Azure solutions" (20-25%).

Each entry records the error code, the message, the cause, the fix, and the week
it was first encountered.

## RequestDisallowedByAzure

| Field | Detail |
| ----- | ------ |
| Week | 01 |
| Service | Azure Container Registry |

**Message**

```
(RequestDisallowedByAzure) Resource 'acrai200dev' was disallowed by Azure: The
selected region is currently not accepting new customers:
https://aka.ms/locationineligible.
Code: RequestDisallowedByAzure
```

**Cause**

The target region is not accepting new customers. Azure caps new resource
creation in regions that are at capacity, independent of the subscription or the
resource type. West Europe was affected.

**Fix**

Create the resource in a different region. The resource group was first recreated
in `northeurope`, and later the whole roadmap moved to `swedencentral` after a
separate App Service VM quota block (see below). `swedencentral` is now the
standard region. See [`environment.md`](environment.md) for the full region
history.

## MissingSubscriptionRegistration

| Field | Detail |
| ----- | ------ |
| Week | 01 |
| Service | Azure Container Registry (applies to any provider) |

**Message**

```
(MissingSubscriptionRegistration) The subscription is not registered to use
namespace 'Microsoft.ContainerRegistry'.
Code: MissingSubscriptionRegistration
```

**Cause**

The resource provider for the service is not registered on the subscription. New
Pay-As-You-Go subscriptions start with most providers unregistered. The portal
registers a provider silently on first use through the UI; the Azure CLI does
not, so the first CLI create fails.

**Fix**

Register the provider, then retry:

```bash
az provider register --namespace Microsoft.ContainerRegistry --wait
```

Registration is free and permanent. To avoid repeating this per service, all
providers the roadmap needs were registered up front. The full list, the
bulk-registration approach, and the check command are in
[`environment.md`](environment.md).

## Operation cannot be completed without additional quota

| Field | Detail |
| ----- | ------ |
| Week | 01 |
| Service | Azure App Service plan |

**Message**

```
Operation cannot be completed without additional quota.
Current Limit (Total Regional VMs): 0
Current Usage: 0
Amount required for this deployment: 1
```

**Cause**

The region has zero App Service VM quota for the subscription. The quota is
regional and tier-independent: a B1 plan failed identically to F1, because the
limit is on VMs allocatable in the region, not on the tier. New Pay-As-You-Go
subscriptions can start with zero quota in a region even when other regions have
headroom. This was hit in `northeurope`.

**Fix**

Create the plan in a region that has quota. The plan was created in
`swedencentral`, which became the standard region for the roadmap. Before any
compute-provisioning week, run the pre-flight quota check in
[`environment.md`](environment.md). Quota increases can also be requested via
Subscription > Usage + quotas > Request increase (usually auto-approved on PAYG,
no cost).

## HTTP 503 after container web app create

| Field | Detail |
| ----- | ------ |
| Week | 01 |
| Service | Azure App Service (container) |

**Message**

```
HTTP 503 Service Unavailable
(returned by the web app after az webapp create, container never becomes healthy)
```

**Cause**

The web app exists and routes traffic, but the image pull from ACR was rejected
because no registry authentication was configured. The site responds, the
container never comes up. A separate but easily confused cause of a 503 on a
container that is actually running is a port mismatch: `WEBSITES_PORT` must match
the port the app binds to (8000 for uvicorn). In the port-mismatch case the logs
look healthy.

**Fix**

Configure registry authentication with a system-assigned managed identity:

1. Assign a system-assigned managed identity to the web app.
2. Grant that principal `AcrPull`, scoped to the ACR resource ID.
3. Set `acrUseManagedIdentityCreds = true` on the web app (in Deployment Center >
   Settings > Authentication > Managed Identity). The pull fails without this
   flag even after steps 1 and 2.

For a running container, confirm `WEBSITES_PORT` matches the bound port.

## HTTP 403, app state QuotaExceeded

| Field | Detail |
| ----- | ------ |
| Week | 01 |
| Service | Azure App Service plan (F1 Free) |

**Message**

```
HTTP 403 Forbidden
App state: QuotaExceeded
```

**Cause**

The F1 Free tier daily limits are hard cutoffs, not throttles: roughly 60
CPU-minutes and ~165 MB outbound data per day. When a limit is hit, App Service
sets the app state to `QuotaExceeded` and returns HTTP 403 until the counter
resets at UTC midnight. The app is not crashed and the logs look healthy. This
bites container workloads because each failed pull, restart, and cold start
re-pulls the image (the `retrieval-api` image is ~150 MB against the ~165 MB
daily egress allowance), so a few iterations exhaust the quota. F1 also disables
Always On, so the container unloads after ~20 minutes idle and cold-starts with a
full re-pull.

**Fix**

Upgrade the plan to a paid tier so the daily quota no longer applies:

```bash
az appservice plan update -g rg-ai200-dev -n asp-ai200-dev --sku B1
az webapp restart -g rg-ai200-dev -n <APP_NAME>
```

B1 removes the daily cutoff and enables Always On and SSH. It bills continuously
(~$13/mo estimate), so delete the plan the same day the lab ends.

## exec fails on a scaled-to-zero Container App

| Field | Detail |
| ----- | ------ |
| Week | 02 |
| Service | Azure Container Apps |

**Message**

```
az containerapp exec fails to connect (no running replica to attach to)
when the app is at min-replicas 0 and idle.
```

**Cause**

Exec attaches a shell to a running container. With `--min-replicas 0` and no
traffic, KEDA has scaled the app to zero, so there is no replica to attach to.
This is the same coin as scale-to-zero's free idle: nothing is running to connect
to.

**Fix**

Wake a replica first, then exec:

```bash
# wake it with a request
curl -s https://$FQDN/health
# or keep a warm replica for the debugging session
az containerapp update -n ca-retrieval-api -g rg-ai200-dev --min-replicas 1
```

Set `min-replicas` back to 0 afterwards if the free idle is wanted.

## Pasting `#` comment lines into zsh throws command-not-found errors

| Field | Detail |
| ----- | ------ |
| Week | 02 |
| Service | Shell / zsh (lab tooling) |

**Message**

```
command not found: #
zsh: number expected
(cosmetic errors when a block with `#` comment lines is pasted interactively)
```

**Cause**

Pasting a multi-line block that contains `#` comment lines into an interactive zsh
session evaluates the comment text as commands. The actual `az` commands still run;
the errors are cosmetic noise from the comment lines only.

**Fix**

Run the block as a script (`bash commands.sh`), or strip the comment lines before
pasting. The lab command files
[`../labs/02-container-apps/commands.sh`](../labs/02-container-apps/commands.sh) and
[`../labs/02-container-apps/commands-manage.sh`](../labs/02-container-apps/commands-manage.sh)
carry this warning at the top for the same reason.

## Container restarts under load but runs fine when idle

| Field | Detail |
| ----- | ------ |
| Week | 02 |
| Service | Azure Container Apps |

**Message**

```
Replica restarts repeatedly once traffic arrives. Liveness probe reports the
container unhealthy. No application error in the logs; the process is simply gone
and restarted. The same image runs indefinitely while idle.
```

**Cause**

Under-resourced replica, not an application defect. Memory too small gets the
container OOM-killed under load; CPU too small starves it until requests time out and
the probe fails. Either way the platform restarts it, so a liveness probe faithfully
reports "unhealthy" when the truth is "too small." The load-dependent pattern is the
signature: idle fits in the allocation, load does not.

**Fix**

Increase the allocation, respecting the fixed 1 vCPU : 2 GiB ratio, or scale out
sooner so no single replica takes enough load to die:

```bash
# bigger replicas (valid pairings only: 0.25/0.5Gi, 0.5/1Gi, 1/2Gi, ...)
az containerapp update -n ca-retrieval-api -g rg-ai200-dev --cpu 0.5 --memory 1Gi
# or more replicas
az containerapp update -n ca-retrieval-api -g rg-ai200-dev --max-replicas 5
```

Do not start by debugging the application. Note also that replica count is KEDA's
concern and replica size is the compute scheduler's; "the app is slow" can be either,
and they have different fixes. See
[`../notes/02b-container-apps-manage.md`](../notes/02b-container-apps-manage.md).

## New revision unexpectedly took 100% of traffic

| Field | Detail |
| ----- | ------ |
| Week | 02 |
| Service | Azure Container Apps |

**Message**

```
No error. `az containerapp update` in multiple revision mode was expected to create a
revision at 0% traffic; the new revision took 100% and served every request
immediately.
```

**Cause**

Multiple revision mode only permits revisions to coexist. It does not pin traffic. With
traffic left unpinned (floating), `latest` inherits 100% on every deploy, so a new
revision goes live to everyone. Revision mode and traffic weights are two separate
settings, and only the second one holds traffic still.

**Fix**

Pin traffic to the current revision by name before deploying. That is the act that arms
the 0%-canary behaviour:

```bash
az containerapp ingress traffic set -n ca-retrieval-api -g rg-ai200-dev \
  --revision-weight ca-retrieval-api--0000004=100
```

Subsequent deploys then arrive live but at 0% traffic until weights are dialled
explicitly.

## Probes show tcpSocket that were never configured

| Field | Detail |
| ----- | ------ |
| Week | 02 |
| Service | Azure Container Apps |

**Message**

```
az containerapp show --query "properties.template.containers[0].probes"
returns Liveness/Readiness/Startup probes of type tcpSocket on an app where no probes
were ever defined (readiness showing failureThreshold: 48).
```

**Cause**

Container Apps auto-generates default probes when none are configured, and the defaults
are TCP. There is no blank slate. `failureThreshold: 48` is Azure's default value, not
a chosen one. A TCP probe only proves the port is open, so a wedged app holding its
listening socket while unable to serve passes it. The weak default is the problem, not
the presence of probes.

**Fix**

Export the spec, convert the probes to HTTP against a real health endpoint, apply, then
verify what actually landed (YAML indentation is unforgiving and the update will accept
a misplaced block):

```bash
az containerapp show -n ca-retrieval-api -g rg-ai200-dev -o yaml > app.yaml
# edit: replace each tcpSocket block with httpGet { path: /health, port: 8000 }
az containerapp update -n ca-retrieval-api -g rg-ai200-dev --yaml app.yaml
az containerapp show -n ca-retrieval-api -g rg-ai200-dev \
  --query "properties.template.containers[0].probes" -o yaml
```

The exported `app.yaml` contains the subscription, tenant, and principal IDs verbatim.
It is git-ignored, not committed.

## Container App in a restart loop

| Field | Detail |
| ----- | ------ |
| Week | 02 |
| Service | Azure Container Apps |

**Message**

```
Replica restarts continuously. Logs show the app beginning to start, then the process
terminating before it finishes booting, repeatedly.
```

**Cause**

An over-aggressive liveness probe, or a missing startup probe. Liveness kills the
container when it fails past its threshold. If the timeout is too short or the
threshold too low, it fires during boot, a garbage-collection pause, or a slow request,
kills a container that was fine, and then fires again during the restart's boot. The
probe manufactures the outage it exists to prevent.

The underlying reason a startup probe is needed at all: "no response" means different
things at different times. During boot it is expected and the right action is to wait;
after boot it is alarming and the right action is to kill. Only elapsed time
distinguishes the two, and the startup probe is the gate that switches the
interpretation.

**Fix**

Add or widen the startup probe so liveness is held off until boot completes. The grace
window is `failureThreshold × periodSeconds` (6 × 5s = 30s). Then loosen liveness:
raise `timeoutSeconds` and `failureThreshold` so a transient stall is not fatal.
Readiness, not liveness, is the probe that should react quickly, because it only
withholds traffic instead of killing the container: readiness is traffic, liveness is
life.

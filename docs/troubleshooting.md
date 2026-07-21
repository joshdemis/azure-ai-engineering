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

# Environment

Reference for the Azure environment used across the AI-200 roadmap. Records the
subscription, region, resource group, tagging, tooling, naming rules, and the
resource providers registered for the 13-week plan.

## Subscription

| Field | Value |
| ----- | ----- |
| Type | Personal Pay-As-You-Go |
| Subscription ID | `<SUBSCRIPTION_ID>` |

The real subscription ID is never committed. See
[`security-conventions.md`](security-conventions.md) for redaction rules.

## Region

Standard region for all 13 weeks: `swedencentral`.

Region history (three moves before landing on the standard):

1. `westeurope`. First choice. Creating the container registry there failed with
   `RequestDisallowedByAzure`: the region is not currently accepting new
   customers (https://aka.ms/locationineligible).
2. `northeurope`. The resource group was recreated here, the nearest viable
   region to Rotterdam. ACR worked. Later, App Service plan creation failed here
   with zero App Service VM quota (`Total Regional VMs: 0`), and the quota was
   regional and tier-independent, so B1 failed identically to F1.
3. `swedencentral`. App Service plan creation succeeded. This is now the default
   for every resource in this roadmap, and ACR was migrated here. Full error
   detail for each move is logged in [`troubleshooting.md`](troubleshooting.md).

### Pre-flight quota check

Run before any compute-provisioning week (3, 4, 5) to confirm the region has
allocatable VM quota before creating a plan:

```bash
az vm list-usage --location swedencentral \
  --query "[?contains(localName,'Total Regional')].{Name:localName,Used:currentValue,Limit:limit}" \
  -o table
```

Quota increases are requested via Subscription > Usage + quotas > Request
increase. On Pay-As-You-Go they are usually auto-approved and cost nothing. Quota
is permission to allocate, not allocation, so raising it does not itself create or
bill for anything.

## Resource group

| Field | Value |
| ----- | ----- |
| Name | `rg-ai200-dev` |
| Region | `swedencentral` |

## Standard tags

Applied to every resource group and resource so cost and ownership are always
attributable.

| Tag | Value |
| --- | ----- |
| `Environment` | `Learning` |
| `Project` | `AI-200` |
| `Owner` | `Josh` |
| `Purpose` | `Study` |
| `Week` | `XX` (two-digit week the resource was created, for example `01`) |

## Local tooling

| Tool | Notes |
| ---- | ----- |
| Azure CLI | Installed on macOS. Primary interface for all provisioning. |
| Azure Cloud Shell | Browser fallback when local CLI is unavailable. |
| Docker | Not required locally. Images are built in the cloud with `az acr build` (ACR Tasks quick tasks). |

## Resource inventory

| Service | Name | SKU | Created | Delete by |
| ------- | ---- | --- | ------- | --------- |
| Azure Container Registry | `acrai200dev` | Basic | Week 01 (2026-07) | Keep through Week 5, delete, recreate Week 13 |

Configuration flags for the registry: `adminUserEnabled: false`,
`anonymousPullEnabled: false`. Cost detail is tracked in
[`cost-matrix.md`](cost-matrix.md).

## Naming convention

Standard pattern: `<type>-ai200-dev`, where `<type>` is a short abbreviation of
the service.

| Service | Name |
| ------- | ---- |
| Resource Group | `rg-ai200-dev` |
| Key Vault | `kv-ai200-dev` |
| Azure OpenAI | `aoai-ai200-dev` |
| Container Apps | `ca-ai200-dev` |
| AI Search | `ais-ai200-dev` |
| Redis | `redis-ai200-dev` |
| PostgreSQL | `pgsql-ai200-dev` |

### Exceptions

Some Azure resource types do not allow hyphens in their names, so they cannot
follow the `<type>-ai200-dev` pattern.

| Service | Name | Rule |
| ------- | ---- | ---- |
| Container Registry | `acrai200dev` | ACR names are alphanumeric only, 5-50 characters, no hyphens. The intuitive `acr-ai200-dev` is invalid. |
| Storage | `stai200dev` | Storage account names are alphanumeric only, lowercase, 3-24 characters, no hyphens. |

The container registry is the exception encountered in Week 1. Storage accounts
share the same alphanumeric-only constraint and are listed here so the rule is
recorded in one place before that service is provisioned.

## Resource providers

A resource provider is the Azure service namespace that supplies a family of
resource types, for example `Microsoft.ContainerRegistry` provides registries.
Azure only lets a subscription create resources from providers that are
registered on that subscription.

New Pay-As-You-Go subscriptions start with most providers unregistered. The
Azure portal registers a provider silently the first time you create a matching
resource through the UI, so this is invisible when clicking through the portal.
The Azure CLI does not auto-register, so the first CLI create for an
unregistered provider fails.

In Week 1, `az acr create` failed with `MissingSubscriptionRegistration` because
`Microsoft.ContainerRegistry` was not registered. The fix:

```bash
az provider register --namespace Microsoft.ContainerRegistry --wait
```

Registration is free and permanent. It grants no resources by itself and incurs
no cost. To avoid hitting the same error later in the roadmap, every provider
the 13-week plan needs was bulk-registered up front:

- `Microsoft.ContainerRegistry`
- `Microsoft.App`
- `Microsoft.Web`
- `Microsoft.ContainerService`
- `Microsoft.DocumentDB`
- `Microsoft.DBforPostgreSQL`
- `Microsoft.Cache`
- `Microsoft.ServiceBus`
- `Microsoft.EventGrid`
- `Microsoft.KeyVault`
- `Microsoft.AppConfiguration`
- `Microsoft.Insights`
- `Microsoft.OperationalInsights`
- `Microsoft.CognitiveServices`
- `Microsoft.Storage`

Check which providers are registered:

```bash
az provider list --query "[?registrationState=='Registered'].namespace" -o tsv | sort
```

The `MissingSubscriptionRegistration` error is logged in
[`troubleshooting.md`](troubleshooting.md).

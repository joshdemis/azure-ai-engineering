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

Create the resource in a different region. The resource group was recreated in
`northeurope`, which is now the standard region for the roadmap. See
[`environment.md`](environment.md) for the region decision.

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

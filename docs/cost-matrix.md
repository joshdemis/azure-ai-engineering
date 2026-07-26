# Cost Matrix

Cost tracking for every Azure resource used in the roadmap. Before creating any
resource I answer three questions:

1. What does it do?
2. What does it cost (to keep running, and per use)?
3. How do I delete it?

If any of the three is unclear, the resource is not created yet.

## Matrix

| Service | Free Tier | Running Cost | Usage Cost | Delete After Lab |
| ------- | --------- | ------------ | ---------- | ---------------- |
| Azure Container Registry (Basic) | No | Yes (~$5/mo) | ACR Tasks compute, negligible | No, keep through Week 5, delete, recreate Week 13 |
| App Service plan | Yes (F1, unusable for containers) | Yes, B1 ~$13/mo (~$0.018/hr) | No | Yes, always, same day |
| Container Apps (Consumption) | Yes (monthly grant) | No, scales to zero | vCPU/memory-seconds beyond the grant | Environment yes, unless continuing to module 2/3 |
| Log Analytics workspace (auto-created by the environment) | Yes (free ingestion allowance) | No standing charge | Ingestion beyond the allowance, small at lab volume | Deleted with the environment |

## Container Apps: what the usage cost is actually metered on

Consumption-plan usage cost is metered per replica over time, on both dimensions:
vCPU-seconds and memory GiB-seconds. So the bill is roughly

```
per-replica size × seconds each replica runs × number of replicas
```

Three consequences for the two levers touched in week 2, module 2:

- **Right-sizing down reduces cost directly.** Dropping from 0.5 vCPU / 1 GiB to
  0.25 vCPU / 0.5 GiB halves the per-second rate of every replica. The CPU:memory ratio
  is fixed at 1:2, so both dimensions move together and there is no way to shave one
  without the other.
- **Scaling out is cheaper than scaling up for bursty load,** because the units added
  and removed are small and short-lived. Few large replicas hold cost flat regardless
  of load; many small replicas track it.
- **Multiple revision mode can multiply the bill.** Revisions left live for
  instant-rollback purposes still run replicas and still meter. They cost nothing only
  while scaled to zero, which for a revision at 0% traffic depends on its
  `min-replicas`. A revision kept warm at `min-replicas 1` is a standing charge.
  Deactivate revisions that are no longer needed as rollback targets.

Neither lever changes the free monthly grant, which is applied against total
vCPU-seconds and GiB-seconds for the subscription.

## Pricing accuracy

All figures here are estimates. Verify against the
[Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) and
against actual Cost Analysis in the portal before relying on them for any
decision. Prices vary by region and change over time.

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

## Pricing accuracy

All figures here are estimates. Verify against the
[Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) and
against actual Cost Analysis in the portal before relying on them for any
decision. Prices vary by region and change over time.

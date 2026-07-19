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

## Pricing accuracy

All figures here are estimates. Verify against the
[Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) and
against actual Cost Analysis in the portal before relying on them for any
decision. Prices vary by region and change over time.

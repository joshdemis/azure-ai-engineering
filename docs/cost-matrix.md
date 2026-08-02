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
| Storage account (Standard LRS, queue for the KEDA scaler) | No, but negligible at lab volume | Minimal (per GB stored; a queue of 20 messages is effectively nothing) | Per transaction (put, peek, get). KEDA polling the queue is itself billable transactions. | Yes, same day |
| Azure Kubernetes Service | Control plane only (`--tier free`). Nodes are never free. | Yes, and it does not stop: nodes bill continuously with no scale-to-zero (~$0.20/hr for 2 × `standard_d2s_v6`) | Azure Load Balancer plus a public IP if a Service uses `type: LoadBalancer` | Yes, always, same day |

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

## The scale rule is a cost control, and it can silently stop being one

Week 2, module 3 added the third lever: the scale rule decides how many replicas run,
and therefore how many replica-seconds are metered.

The trap found in the lab is worth recording, because it costs money quietly rather than
failing loudly. **A revision whose scale rule watches a signal that never falls will
hold replicas indefinitely.** The queue scale rule targeted 5 messages per replica
against a 20-message queue, so KEDA started 4 replicas, correctly. But the image is not
a queue consumer, so nothing drained the queue, the depth stayed at 20, and the replica
count stayed at 4. `min-replicas 0` was set the whole time and made no difference: the
floor was never reached because the rule kept asking for 4.

Nothing errors in this state. The app looks healthy and simply bills continuously.

Two rules that follow:

- Before walking away from a queue-scaled or event-scaled app, confirm the signal can
  actually reach zero. If nothing is consuming, reset the app to a rule that can (an
  HTTP rule), or set `max-replicas 0` while it is idle.
- CPU and memory rules cannot reach zero by design, so an app using them has a permanent
  floor of one replica and a permanent standing charge. That is a cost decision, not
  only an architectural one. See
  [`../labs/02-container-apps/02c-container-apps-scale.md`](../labs/02-container-apps/02c-container-apps-scale.md).

Storage account note: the account backing the queue is cheap to keep but pointless to
keep, and it is the one resource from module 3 that bills while idle. Delete it with the
lab.

## AKS: the one service that can drain the budget

Every other compute service in the roadmap either scales to zero or bills a small fixed
amount. AKS does neither. Nodes are VMs, they bill per hour whether or not a single pod is
scheduled on them, and Kubernetes has no native scale-to-zero. An idle cluster costs
exactly as much as a busy one.

That makes the discipline different from week 2's. With Container Apps, forgetting to
delete something cost nothing while it was idle. Here, forgetting is the entire risk:
$0.20/hr is trivial for a three-hour lab and roughly $145 for a month left running.

The rule is unconditional: **create, run the lab, delete the cluster the same day.**

Two levers on the node bill, both chosen before the cluster is created:

- **vCPU count.** Cost scales with total vCPUs across the node pool, so it is node count
  multiplied by size. Pick the smallest count that runs the lab.
- **Series.** B-series is burstable and cheaper, suited to intermittent load; D-series is
  general purpose and steady. Size choice is constrained by quota as well as price, and
  the three gates a size has to clear are in
  [`troubleshooting.md`](troubleshooting.md).

The control plane is free on `--tier free`, so nodes are the whole bill. The one usage
cost to watch is a Service of `type: LoadBalancer`, which provisions a real Azure Load
Balancer and a public IP, both billable. `ClusterIP` plus `kubectl port-forward` gives the
same access for a lab at zero cost and leaves nothing behind when the tunnel closes.

## Pricing accuracy

All figures here are estimates. Verify against the
[Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) and
against actual Cost Analysis in the portal before relying on them for any
decision. Prices vary by region and change over time.

# Week 2, module 3: Scale containers in Azure Container Apps

Learning path: Deploy and manage apps on Azure Container Apps (module 3 of 3)
Exam domain: Develop containerized solutions on Azure (20-25%)

Week index: [`../../notes/week-02.md`](../../notes/week-02.md)
Module 1 notes: [`../../notes/week-02.md`](../../notes/week-02.md) (section "Module 1: Deploy containers to Azure Container Apps")
Module 2 notes: [`02b-container-apps-manage.md`](02b-container-apps-manage.md)
Module 3 commands: [`commands-scale.sh`](commands-scale.sh)

## Framing: a scale rule is a trigger plus an arithmetic

Modules 1 and 2 kept naming KEDA without ever configuring it. Scale-to-zero was
"KEDA drives the replica count." Replica sizing was explicitly *not* KEDA's job. Every
time the question "so how many replicas, and why that many?" came up, the answer was
deferred. Module 3 is where it gets built.

The definition that makes the whole module fall into place:

**A scale rule is a trigger (a signal KEDA watches) plus the numbers that map that
signal to a replica count.**

Three pieces, and keeping them separate is most of the understanding:

| Piece | What it sets | Example |
| ----- | ------------ | ------- |
| `--min-replicas` / `--max-replicas` | The **range**. A hard floor and ceiling. | 0 to 5 |
| The scale rule | **Where in that range** the app sits right now, given the signal. | 10 concurrent requests per replica |
| KEDA | The **engine** that reads the signal and evaluates the rule. | polls, computes, adjusts |

Min and max are not a scaling policy. They are the boundaries a policy operates
inside. Setting `--max-replicas 10` with no rule does not produce 10 replicas; it
permits up to 10 if some rule ever asks for them. That distinction is worth holding
onto, because a common misreading is treating max-replicas as a target.

## The scale rule types

Four categories, distinguished by where the signal comes from.

| Type | Signal | Typical use | Can scale to zero |
| ---- | ------ | ----------- | ----------------- |
| HTTP | Concurrent requests at ingress | Web APIs, the default case | Yes |
| TCP | Concurrent connections | Non-HTTP protocols (custom wire formats, databases, game servers) | Yes |
| CPU | CPU utilisation inside the replica | Compute-bound work with no external queue | No, floor of 1 |
| Memory | Memory utilisation inside the replica | Memory-bound work, large in-process caches | No, floor of 1 |
| Custom (KEDA scalers) | An external event source | Queue workers, stream consumers, event-driven anything | Yes, for most |

### HTTP is the default, and it has been running the whole time

The detail that reframes the previous two modules: **if no scale rule is configured,
Container Apps applies an implicit HTTP scale rule.** That implicit rule is what has
been waking the app on every `curl` since module 1. The exec-fails-at-zero problem, the
cold start on the first request after idle, the replica that appeared when traffic
arrived: all of that was a scale rule doing its job, unconfigured and unnamed.

So module 3 is not adding scaling to an app that had none. It is making an existing
implicit behaviour explicit, then replacing it with a different signal. Writing the
rule out by hand is what turns a default into a decision:

```bash
az containerapp update -n ca-retrieval-api -g rg-ai200-dev \
  --min-replicas 0 --max-replicas 5 \
  --scale-rule-name http-rule --scale-rule-type http \
  --scale-rule-http-concurrency 10
```

`http-concurrency 10` means "target roughly 10 concurrent requests per replica." It is
a target, not a hard limit: KEDA divides observed concurrency by 10 and adjusts toward
that many replicas, capped by max.

### Custom KEDA scalers are the reason the platform is interesting

KEDA ships roughly 60 built-in scalers: Azure Service Bus, Azure Storage Queue, Azure
Event Hubs, Kafka, RabbitMQ, Redis, Prometheus, cron, and so on. Each one knows how to
read a specific external system and report a number.

This is the leap from "web app that scales with traffic" to "event-driven compute."
Without a custom scaler, replica count can only track requests arriving at the front
door. With one, replica count tracks work waiting anywhere the platform can reach,
which is what makes a backend worker with no HTTP surface at all a first-class citizen
on this platform.

## The scale-to-zero rule (the deepest idea in the module)

CPU and memory rules cannot scale to zero. The obvious explanation is wrong, and the
real one generalises to every scaler that will ever be encountered.

The wrong explanation: "CPU is never actually zero, so the rule never says stop."

The real rule:

> **A scaler can reach zero if and only if its signal is observable while zero replicas
> are running.**

The test is not what the signal measures. It is **where the signal is measured**.

**External signals** live outside the replicas:

- HTTP request count is measured at **ingress**. Ingress is platform infrastructure and
  exists whether or not any replica does.
- Queue depth is measured **in the queue**. The queue is a separate Azure resource with
  its own lifetime.
- Service Bus message count, Event Hub lag, a Redis list length: all of them are
  properties of some other system.

At zero replicas these signals are still readable, so KEDA can see work arriving and
start the first replica. Scaling *from* zero is possible precisely because something
outside the app is holding the evidence that work exists.

**Internal signals** live inside a replica:

- CPU utilisation is measured **inside a container**.
- Memory utilisation is measured **inside a container**.

At zero replicas there is no container. The signal does not read zero; the signal
**does not exist**. There is nothing to sample. That produces a chicken-and-egg: a
running replica would be required to generate the CPU reading that would tell KEDA to
start a replica. So CPU and memory rules have a hard floor of one replica, and the
platform enforces it.

Stated as a decision procedure, which is how it is actually useful: to know whether a
scaler can reach zero, ask where its number comes from. Outside the app, it can. Inside
the app, it cannot.

The architectural consequence is worth being explicit about. If the goal is zero idle
cost, the workload must be driven by something externally observable. An app that only
knows it is busy by looking at its own CPU is an app that must always be paying for at
least one replica. Choosing a queue-driven design over a self-polling design is
therefore also a cost decision, not just a plumbing preference.

## Scale up fast, scale down slow

KEDA adds replicas quickly and removes them cautiously, with a cool-down period of
roughly five minutes before a replica is actually removed. That asymmetry is
deliberate, and the reasoning behind it is more valuable than the number.

Work through the four ways of being wrong:

| Mistake | Consequence | Cost |
| ------- | ----------- | ---- |
| Scale up too slowly | Requests queue behind insufficient replicas, users wait or time out | High, and user-visible |
| Scale up too quickly | Briefly run a replica that was not needed | Pennies |
| Scale down too slowly | Run a spare replica for a few extra minutes | Pennies |
| Scale down too quickly | Replica killed, load returns seconds later, every request in the gap pays a full cold start (image pull, boot, port bind). On bursty traffic this becomes a thrash cycle of kill and restart. | High, and user-visible |

Both expensive mistakes are on the same side: under-reacting on the way up and
over-reacting on the way down. Both cheap mistakes are on the other. So the tuning is
obvious once the table is written out: move fast in the direction where hesitation
hurts, move slowly in the direction where haste hurts.

The generalisable principle:

> **When the penalties for over-reacting and under-reacting are asymmetric, tune toward
> the cheaper mistake.**

Wrongful-keep costs pennies. Wrongful-kill costs cold starts and possibly a thrash
loop. Therefore bias toward keeping.

This is exactly the shape of module 2's liveness probe reasoning, where
`failureThreshold: 3` exists so that one failed check does not kill a healthy
container. Same asymmetry, different layer: killing something that was fine is
expensive, waiting one more interval is cheap, so wait. The pattern recurs across
retry policies, circuit breakers, alert thresholds, and cache eviction. Once the two
error costs are named, the tuning direction stops being a guess.

## Traffic and scaling are independent systems

This is the payoff from the queue-scaler lab, and it corrected a genuinely wrong mental
model. Going in, I had traffic weights and replica counts vaguely coupled: more traffic
share implies more replicas, and a revision at 0% traffic implies an idle revision.

They are two separate systems that do not talk to each other.

| System | Component | Question it answers |
| ------ | --------- | ------------------- |
| Traffic weight | Ingress | Of the HTTP requests arriving, what share does this revision serve? |
| Scale rule | KEDA | How many replicas does this revision run to handle its work? |

The consequences, in increasing order of usefulness:

1. **A revision at 0% HTTP traffic can still run N replicas.** If its scale rule watches
   a queue, and that queue has depth, KEDA starts replicas regardless of the fact that
   ingress is sending it nothing. The lab demonstrated this directly: the revision was
   scaled up by queue depth while the traffic dial was irrelevant to the outcome.
2. **A workload with no ingress at all still scales.** A queue worker has no FQDN and no
   traffic weight to speak of. Its replica count is driven entirely by queue depth. The
   traffic system simply is not in the picture.
3. **The two can be set independently and deliberately.** Pinning traffic for a canary
   (module 2) says nothing about how either revision scales. Changing a scale rule says
   nothing about who gets requests.

### Why this matters for ConspiraGraph

The project spec already separates ingestion from retrieval as two services. This
module explains why that separation is right rather than merely tidy:

- The **ingestion worker** scales on queue depth. It ignores HTTP entirely. When a
  backlog appears it scales out to drain it, then falls back to zero. Idle cost is zero
  because queue depth is externally observable.
- The **retrieval API** scales on HTTP concurrency. It ignores the queue entirely.
  Its replica count tracks users querying, not documents waiting.

Two services, two independent signals, one environment (sharing the VNet and the Log
Analytics workspace from module 1). Merging them into one app would force a single
scale rule to serve two unrelated load shapes, and neither signal would size the other
workload correctly. The scaling model is an argument for the service boundary, not just
a consequence of it.

## Building a KEDA queue scaler

HTTP scaling worked with no setup because ingress already existed, the platform already
counted requests, and `curl` already generated load. A queue scaler needs all three of
those supplied by hand:

1. **A queue to watch.** An Azure Storage account with a queue in it.
2. **Credentials to read it.** KEDA has to authenticate to that storage account.
3. **Messages to put in it.** Something has to create the backlog.

Step 2 is the interesting one.

### Auth: managed identity over the account key

Two options for letting KEDA read the queue.

**Connection string or account key.** Fewer commands. The key goes into the app's
secret store and the scale rule reads it from there.

**Managed identity.** The app's existing system-assigned identity gets a role on the
storage account, and the scale rule is told to authenticate as that identity.

Managed identity was chosen, for two distinct reasons that are worth separating because
they are often collapsed into one:

1. **No secret exists to leak.** There is no key stored in the app, no key in the shell
   history, no key in a screenshot, nothing to rotate. This is the same argument as the
   ACR pull in module 1.
2. **Least privilege.** This one is specific to storage and is the stronger argument. A
   storage account key is a **master key**: it grants full control of the entire storage
   account, every blob, table, file share, and queue, with read and write and delete. It
   cannot be narrowed. The managed-identity path uses the `Storage Queue Data Reader`
   role, which grants reading queue data and nothing else. Not blobs, not tables, not
   writing, not deleting. A scaler that only needs to count messages gets permission to
   only count messages.

The trade-off is honest: managed identity is more setup. KEDA has to be told which
identity to use (`--scale-rule-identity system`), and the role assignment has to
propagate. That is a small one-time cost paid to avoid a large standing risk, which is
the usual shape of a good security decision.

### The managed-identity pattern, fifth time

```bash
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --scope "$STORAGE_ID" \
  --role "Storage Queue Data Reader"
```

Same three-part shape as every previous grant:

| Part | Value here |
| ---- | ---------- |
| Who (principal) | The app's system-assigned identity |
| What (role) | `Storage Queue Data Reader` |
| Where (scope) | This storage account only |

Fifth time through this pattern now (App Service pull to ACR, Container Apps pull to
ACR, and now Container Apps read from Storage Queues). Only the two nouns change: the
role name and the scope resource. It has stopped being something to look up. The exam
version of this is reading a role assignment and saying what it grants, and the answer
is always found in those three fields.

One extra piece that is specific to scale rules and easy to miss:
`--scale-rule-identity system` is the equivalent of module 1's
`registry set --identity system`. Granting the role makes the identity *able* to read
the queue; this flag is what makes KEDA actually *choose* to authenticate as it. Having
a capability and being configured to use it are still two different things, which is
now the third time that same distinction has decided whether something works.

### The arithmetic: `queueLength`

```bash
az containerapp update -n ca-retrieval-api -g rg-ai200-dev \
  --min-replicas 0 --max-replicas 10 \
  --scale-rule-name queue-rule --scale-rule-type azure-queue \
  --scale-rule-metadata "queueName=ingest" "accountName=$STORAGE" "queueLength=5" \
  --scale-rule-identity system
```

`queueLength=5` is the **target number of messages per replica**, not a threshold and
not a total. KEDA divides queue depth by it:

```
replicas = ceil(queue depth / queueLength), capped at max-replicas
```

20 messages with `queueLength=5` gives 4 replicas. The lab showed exactly 4. Raising
`queueLength` means each replica is expected to handle more, so fewer replicas are
started for the same backlog; lowering it scales out harder. The right value depends on
how long one message takes to process, which is an application fact, not a platform
one.

### What the lab actually demonstrated, and what it did not

An important caveat, because getting this wrong would leave a false model in place.

The image running here is the `retrieval-api` FastAPI app from week 1. It is **not a
queue consumer**. It does not connect to the queue, pop messages, or process anything.
So what the lab observed was:

- 20 messages sat in the queue.
- KEDA read a depth of 20, computed 4 replicas, and started 4.
- The 4 replicas did nothing with the queue.
- The depth stayed at 20, so KEDA held at 4 replicas indefinitely.

**Only the scale-up half of the cycle was demonstrated.** With a real worker, each
replica would pop and process messages, depth would fall, KEDA would recompute a
smaller replica count on each poll, and once the queue emptied it would scale back to
zero. The full cycle is depth up, replicas up, depth down, replicas down, zero.

Being precise about what was and was not observed matters more than the demo looking
tidy. The scaler was proven; the drain was not.

The cleanup follows directly from that behaviour: a queue rule against an undrained
queue is a rule that will never let the app reach zero, so the app was reset to a
simple HTTP rule before walking away, and the storage account was deleted because it is
the one artifact in this lab with a standing cost.

## Choosing a scale rule

Reduced to the question actually being answered:

| The work arrives as | Rule | Reaches zero |
| ------------------- | ---- | ------------ |
| HTTP requests | `http`, tuned by concurrency | Yes |
| Connections on a non-HTTP protocol | `tcp` | Yes |
| Messages in a queue or topic | Custom KEDA scaler (`azure-queue`, Service Bus, Kafka, ...) | Yes |
| Compute-bound work with no external signal | `cpu` or `memory` | No, floor of 1 |

And the two sizing questions that sit either side of it, which module 2 established are
owned by different components:

- How **many** replicas: KEDA, via min/max plus the scale rule. This module.
- How **big** each replica: the compute scheduler, via the fixed 1 vCPU : 2 GiB
  pairings. Module 2.

"The app is slow" still splits into those two diagnoses with two different fixes.

## Commands

The full command sequence for this module, each line with an inline comment and in run
order, is in [`commands-scale.sh`](commands-scale.sh) alongside this file. Read the
warning at the top of that file before pasting anything into a terminal.

## What carried forward

- The asymmetric-cost tuning principle is the same reasoning as module 2's liveness
  `failureThreshold`. Naming the cost of each direction of error is what makes the
  tuning direction obvious instead of arbitrary.
- The managed-identity grant is now reflexive: principal, role, scope. Only the nouns
  change.
- Capability is not configuration. `--scale-rule-identity system` sits in the same slot
  as `registry set --identity system` and `acrUseManagedIdentityCreds`, and forgetting
  it produces a silent failure rather than an error at grant time.
- Everything here reappears on AKS in week 3, unmanaged. KEDA is an add-on to install
  and operate rather than a built-in, the Horizontal Pod Autoscaler is the CPU and
  memory equivalent with the same inability to reach zero, and scale-to-zero requires
  KEDA explicitly because Kubernetes does not do it natively. Container Apps is the
  same model with the operational burden removed.

## Open items

- Cool-down and polling intervals were not tuned by hand here, only observed. KEDA
  exposes both; Container Apps' surface for them is `_TBD_` pending a look at the full
  scale block in the YAML spec.
- A real queue consumer to demonstrate the scale-down half of the cycle. Natural fit
  for the ConspiraGraph ingestion worker in the project weeks.
- Multiple scale rules on one app (for example HTTP and queue together) and how KEDA
  reconciles competing replica targets: `_TBD_`, not covered by the module.

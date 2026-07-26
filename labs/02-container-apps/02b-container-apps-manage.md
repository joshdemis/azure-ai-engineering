# Week 2, module 2: Manage containers in Azure Container Apps

Learning path: Deploy and manage apps on Azure Container Apps (module 2 of 3)
Exam domain: Develop containerized solutions on Azure (20-25%), with a large overlap
into Secure, monitor, and troubleshoot Azure solutions (20-25%)

Week index: [`../../notes/week-02.md`](../../notes/week-02.md)
Module 1 notes: [`../../notes/week-02.md`](../../notes/week-02.md) (section "Module 1: Deploy containers to Azure Container Apps")
Module 1 commands: [`commands.sh`](commands.sh)
Module 2 commands: [`commands-manage.sh`](commands-manage.sh)

## Framing: traffic is a dial, not a switch

Module 1 was deploy: get a container running, pull it privately, expose it, look at
its logs. Module 2 is day two. The app already runs; the questions are now how to
update it without breaking anyone, how to prove a new version is safe before it
serves real users, how to diagnose it when it misbehaves, and how big each replica
should be.

One idea unifies all of that. In single revision mode, shipping is a switch: 100% old
becomes 100% new, instantly, with no intermediate state. In multiple revision mode the
switch becomes a percentage dial across revisions that coexist. That single capability
is what makes safe deploys, canary releases, and instant rollback real. Everything
else in this module is either how to arm the dial (revision mode, traffic pinning), how
to know whether to turn it (health probes), or how to size what sits behind it
(resources).

## Ingress: the managed entry point

Ingress recurs constantly from here on, so it is worth a definition rather than
treating it as a flag.

Ingress is the managed entry point that accepts traffic from outside the app and
routes it to containers. It does four jobs that would otherwise have to be wired by
hand:

1. Terminates TLS, so the app itself never handles certificates.
2. Provides the public FQDN (`<app>.<env-suffix>.<region>.azurecontainerapps.io`).
3. Load-balances across the replicas KEDA has running.
4. Splits traffic across revisions by percentage.

That fourth job is the one this module lives on. Conceptually it is the same thing as
a Kubernetes Ingress or a load balancer frontend, managed rather than self-run, which
is consistent with the rest of Container Apps: Kubernetes behaviour without a cluster
to operate.

`--ingress external` (set back in module 1) is what turns ingress on and makes it
publicly reachable. `internal` would keep the FQDN resolvable only inside the
environment's shared VNet, which is the microservices case from module 1.

## Revision mode and traffic weights are two separate settings

This is the distinction that most of the module hangs on, and conflating the two is
the easiest way to be surprised by a deploy.

| Setting | Command | Question it answers |
| ------- | ------- | ------------------- |
| Revision mode | `revision set-mode --mode single\|multiple` | Can more than one revision be live at once? |
| Traffic weights | `ingress traffic set --revision-weight` | Who gets what share of requests? |

Mode is about coexistence:

- Single (the default): activating a new revision automatically gives it 100% of
  traffic and deactivates the old one, scaling it to zero.
- Multiple: revisions coexist, all active, all able to serve.

Weights are about distribution. They must sum to 100. They are not automatic and not
round-robin across whatever happens to be active; they are explicitly assigned per
revision name.

The consequence worth internalising: flipping to multiple mode splits nothing by
itself. It only permits coexistence. Turning the dial is a separate deliberate act.

The decoupling is useful, not accidental. Several revisions can be live (mode) while
100% of traffic goes to one of them (weights). The others sit warm, running, ready,
serving nothing. That is an instant-rollback target rather than wasted capacity: the
whole point is that promoting one is a pointer change, not a redeploy.

## The pinning rule

The naive model going into the lab was "in multiple revision mode, a new revision
arrives at 0% traffic." That is wrong, and the real behaviour is more interesting.

What actually governs it is whether traffic is pinned to named revisions:

- **Traffic unpinned (floating).** On each deploy, `latest` inherits 100%. The new
  revision goes live to everyone automatically. Multiple revision mode does not change
  this.
- **Traffic pinned to named revisions.** A new deploy arrives live but at 0% traffic.
  It is running and healthy and receiving nothing until traffic is dialled to it
  explicitly. This is the canary safety property, and pinning by name is the act that
  arms it.

The design rationale is that the platform infers intent from the traffic
configuration. No pins reads as "just ship latest," which is the convenient default
for an app nobody is watching closely. Pins read as "I am managing this deliberately,
do not move traffic without me," which is the safe default for anything that matters.
Unpinned goes live; pinned goes dark.

The real lab sequence, in order, because the correction is the lesson:

1. Switched to multiple revision mode.
2. Deployed a new revision (`APP_VERSION=0.5.0-canary`) expecting it at 0%.
3. Observed it take 100% instead. Traffic was still unpinned, so `latest` inherited.
4. Pinned traffic by name: `--revision-weight ca-retrieval-api--0000004=100`.
5. Deployed again (`APP_VERSION=0.7.0-canary`). This revision arrived live at 0%, as
   expected the first time.

`latest` is also usable as a weight target, for example
`--revision-weight latest=10 ca-retrieval-api--0000004=90`. It behaves as a moving
pointer to the newest revision, which is convenient for a repeatable canary flow where
the caller does not want to look up revision names every deploy. It is worth knowing
that it is a pointer, not a name, because it means the target changes underneath a
weight that was never edited.

## Deployment strategies are one mechanism with different numbers

Canary, rollback, and blue-green are not three features. They are weighted traffic
across pinned revisions, with different numbers in the same command.

**Canary.** Send the new revision 10%, watch error rate and latency, ramp to 50, then
100 if it holds. The blast radius of a bad deploy is the percentage, and it is chosen
rather than discovered.

**Instant rollback.**

```bash
az containerapp ingress traffic set ... --revision-weight <stable>=100 <canary>=0
```

One command, seconds, no rebuild and no redeploy. The bad revision keeps running at
0%, which means it is still there to inspect and still re-promotable once fixed. This
is the direct answer to module 1's complaint about App Service's in-place restart:
there is no gap, no image pull, and no scramble, because both versions already exist.

**Blue-green.** Two full revisions live, flip 100% between them. Same command, the
extremes instead of a fraction.

Recognising that these are one mechanism is the actual exam skill. A question
describing any of the three is asking about revision mode plus traffic weights.

## Traffic weights are statistical, not a strict rotation

Percentage routing is probabilistic per request, not a deterministic rotation. A 10%
canary over 20 requests produces roughly 2 hits, not exactly 2. The lab run showed
this directly: the split wobbles at small counts. Over 20,000 requests it converges
tightly on 10%.

The operational consequence matters more than the statistics. A low-traffic canary
gives a noisy early signal, so judging a new revision on its first dozen requests is
judging noise. Either wait for enough volume for the sample to mean something, or raise
the canary percentage deliberately to get signal faster and accept the larger blast
radius. That is the real trade-off in canary sizing.

## Health probes: how Container Apps knows a container is ready

Module 1 said a new revision "comes up healthy before it takes traffic." Probes are
what the word healthy actually means there.

The premise is that running is not the same as ready. A process can be up, with its
port open, and still be unable to serve a request: it is loading a model, warming a
cache, waiting on a downstream dependency, or simply wedged. The platform cannot tell
from the outside unless the app is asked.

Three probe types, each answering a different question:

| Probe | Question | On failure | Controls |
| ----- | -------- | ---------- | -------- |
| Startup | Has it finished booting? | Keeps waiting, up to the threshold | When the other two begin |
| Readiness | Can it take traffic right now? | Pulled from the load balancer, not killed | Traffic |
| Liveness | Is it still alive, or wedged? | Killed and restarted | Life |

Startup runs first and holds the other two off, so a slow boot is not mistaken for a
failure. Readiness failing removes the replica from rotation; passing again puts it
back, with no restart involved. Liveness failing past its threshold kills the
container and lets the platform restart it.

The compressed form worth remembering: **readiness is traffic, liveness is life.**
Readiness stops the bleeding (do not route here). Liveness cures the disease (replace
this).

### Why both are needed

Consider an app that starts fine and later hangs: the process is up, the socket is
open, requests never get a response.

With readiness alone, the replica is quarantined. It stops receiving traffic, which is
correct, but it never recovers, because nothing restarts it. If it is the only replica,
zero replicas are serving, indefinitely. The app is now perfectly protected and
completely down.

With liveness, the wedged container is killed and restarted, and it self-heals.

Both exist because "do not route here" and "replace this" are genuinely different
actions, and the right response to a bad replica is usually both in sequence: stop
sending it work, then replace it.

### The crash-loop trap

Liveness is the probe that can cause the outage it is meant to prevent. A liveness
probe with too short a timeout or too low a failure threshold will fire during a
garbage-collection pause, a slow query, or a cold start. It kills a container that was
healthy. The container restarts, the probe fires again during boot because the app is
not up yet, and it gets killed again. That is a crash loop manufactured entirely by
the probe configuration.

Startup probes exist precisely to hold liveness off until boot completes, which breaks
that cycle.

This is a standard troubleshooting-domain scenario: "an app is in a restart loop" maps
to an over-aggressive liveness probe or a missing startup probe far more often than to
application code.

### Startup window arithmetic

The grace period before a startup probe gives up is `failureThreshold × periodSeconds`.
For example 6 attempts at 5 seconds is a 30-second window. This app's startup probe
ended up at `failureThreshold: 10`, `periodSeconds: 1`, which is a 10-second window.

The interesting part is why the startup window is generous while the liveness window
is tight, given both are watching the same signal. Unresponsive means different things
at different times. During boot, no response is expected, so the correct action is to
wait. After boot, no response is alarming, so the correct action is to kill. The signal
is identical; only the interpretation differs, and the startup probe is the gate that
switches which interpretation applies.

So the danger at boot is not a higher crash rate. It is the ambiguity of silence: a
booting app and a wedged app look the same from outside, and only elapsed time
distinguishes them. That is the whole job of the startup probe.

## HTTP versus TCP probes, and Azure's defaults

This was the most useful mistake in the module.

- A **TCP probe** (`tcpSocket`) asks whether the port is open and accepting
  connections. That is a weak signal. A wedged application holds its listening socket
  open while being completely unable to serve, so a TCP liveness probe may never notice
  the hang described above.
- An **HTTP probe** (`httpGet` with a path) asks whether an endpoint returns a success
  status. That is a strong signal, because it proves the application can actually
  respond. `/health` was built into `retrieval-api` in week 1 for exactly this.

The part that is easy to miss: **Container Apps auto-generates default probes when none
are configured, and those defaults are TCP.** An app that was never given a probe
config still has probes, and they are the weak kind. There is no blank slate.

Exporting the app spec to YAML showed exactly that: pre-existing `tcpSocket` probes
that had never been written by hand. Converting all three to `httpGet` with
`path: /health` closed precisely the wedged-app hole reasoned about in the previous
section, which is a satisfying case of theory predicting the configuration bug.

Two further details from the export:

- `failureThreshold: 48` on the default readiness probe is Azure's default value, not
  a considered choice made for this app. Worth knowing before treating an inherited
  number as intentional.
- The edit had to be verified rather than assumed. YAML indentation is unforgiving,
  and `az containerapp update --yaml` will happily accept a file whose probe block did
  not land where intended. The verification step is:

  ```bash
  az containerapp show -n ca-retrieval-api -g rg-ai200-dev \
    --query "properties.template.containers[0].probes" -o yaml
  ```

  Expect `httpGet` and `path: /health` on all three probes, not `tcpSocket`.

The general lesson generalises past probes: inherited defaults are not the same as
sensible defaults. Being able to read a probe configuration and judge whether its
numbers make sense for this application is the troubleshooting skill the exam domain
is testing, and it is not the same as knowing that probes exist.

The YAML export is worth noting for its own sake as well. `az containerapp show -o
yaml` is the declarative form of everything that was built imperatively across two
modules, which is the natural bridge to Bicep and Terraform later in the roadmap:
the same resource, described rather than commanded.

## Resource tuning: sizing each replica

### The ratio is fixed

CPU and memory are locked to a 1 vCPU : 2 GiB ratio. The valid pairings are
0.25 vCPU with 0.5 GiB, 0.5 with 1 GiB, 1 with 2 GiB, and so on. Arbitrary
combinations are rejected: 0.25 vCPU with 2 GiB fails, which the lab confirmed
deliberately rather than taking on faith.

Why it is locked: replicas are scheduled onto the managed Kubernetes nodes underneath
the environment, and fixed shapes bin-pack predictably. Allowing arbitrary
CPU-to-memory ratios would leave nodes with unusable slivers of one resource and none
of the other. This is the same reason cloud VMs come in fixed sizes rather than
per-field sliders. The rejection is the platform declining a shape it cannot schedule
efficiently, not arbitrary strictness.

### Scale up versus scale out

Total compute available to an app is per-replica size multiplied by max replicas.
There are two ways to add capacity: bigger replicas (up) or more replicas (out).

Container Apps favours out. Scale-out is what makes scale-to-zero possible in the
first place, and it is what keeps cost proportional to load, because the unit being
added and removed is small. A design built around few large replicas loses both
properties.

### Sizing failure modes

Too small has two shapes, and both look like application bugs:

- Memory too small leads to OOM-kills under load.
- CPU too small leads to starvation, timeouts, and probe failures.

Either way the container restarts, and a liveness probe faithfully reports "the app is
unhealthy" when the truth is "the app is under-resourced." The diagnostic signature is
specific and worth memorising: a container that restarts under load but runs fine when
idle is a sizing symptom, not a code defect. The fix is more memory, or scaling out
sooner so no single replica takes enough load to die, and not a debugging session in
the application.

Too big is simply paying for headroom that is never used, on every replica, for as
long as it runs.

### Component ownership

Correcting a mistake made this session: I attributed the CPU/memory ratio constraint to
KEDA. That is wrong. KEDA has nothing to do with replica size.

| Concern | Component | Lever |
|---|---|---|
| How **many** replicas | KEDA | min/max replicas, scale rules |
| How **big** each replica | compute scheduler | fixed CPU:memory pairings (1:2) |

KEDA decides count: scale-out, scale-to-zero, and event-driven triggers. The
compute and scheduling layer decides size.

The reason this matters beyond correctness: "the app is slow" can mean too few
replicas (a KEDA and scale-rule problem) or replicas that are too small (a sizing
problem). Different diagnosis, different fix, and neither command touches the other.
Conflating them means tuning the wrong dial and concluding the platform is broken.

## The extension warning

Every `az containerapp` command prints:

```
WARNING: behavior altered by extension: containerapp
```

The Azure CLI ships a stable core plus extensions installed on demand.
`containerapp` is one of those extensions, versioned separately from the CLI core and
still in preview. The warning is the CLI stating that the command being run comes from
an extension rather than core, which is informational, not an error, and not a sign
anything is misconfigured.

Extensions exist for three reasons: they release faster than the core CLI, they keep
preview surface area out of the stable core, and they keep the core install small.

Two operational notes. First, do not suppress it. Blanket-suppressing CLI warnings
hides the ones that matter, and this one costs nothing to read past. Second, the
extension version is part of the reproducible environment: a command that behaves
differently next month is more likely an extension version change than a service
change. `az version` output, including installed extension versions, is recorded in
[`../../docs/environment.md`](../../docs/environment.md).

## Commands

The full command sequence for this module, each line with an inline comment and in run
order, is in [`commands-manage.sh`](commands-manage.sh) alongside this file.

## What carried forward

- Immutability again, one level up. Week 1: images are immutable, addressed by digest.
  Module 1: revisions are immutable snapshots. Module 2 is what immutability buys at
  the operations layer, because rollback is only a pointer change if the old thing
  still exists unchanged.
- `/health`, built in week 1 as a convenience endpoint, turned out to be the thing that
  makes a strong probe possible. Health endpoints are platform integration points, not
  decoration.
- The declarative YAML export is the bridge to infrastructure as code later in the
  roadmap.
- Everything in this module reappears in week 3 on AKS, unmanaged: probes are
  Kubernetes probes with the same three types and the same semantics, traffic splitting
  becomes an ingress controller or a service mesh to configure, and replica sizing
  becomes requests and limits with no fixed ratio and no scheduler picking safe shapes.
  Container Apps is the same model with the sharp edges filed off, which makes it the
  right place to learn the concepts before owning them.

## Open items

- Scale rules themselves (HTTP concurrency, KEDA event triggers) are module 3, not
  covered here. Only replica sizing is.
- Whether the `latest` weight target is safe in a real canary pipeline: it removes the
  need to look up revision names, but it also means the canary target moves on every
  deploy. `_TBD_` pending a real use.
- The exported `app.yaml` is a local working file only. It contains the subscription
  ID, tenant ID, and principal ID verbatim, so it is git-ignored rather than committed.

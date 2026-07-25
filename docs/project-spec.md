# ConspiraGraph — project specification

> End-to-end project for weeks 10-13 of the AI-200 plan. Assembles the services
> learned as standalone labs in weeks 1-9 into one working system.

_Last updated: 2026-07-25_

---

## Overview

ConspiraGraph is a semantic search engine over a corpus of clearly satirical,
fictional conspiracy theories. You search one idea and it returns the most
semantically related theories, plus a graph endpoint that returns theories as
nodes and their pairwise similarities as edges: a "conspiracy web." It is the
retrieval and infrastructure layer of a RAG system without the LLM
answer-generation step.

The playful corpus is deliberate. The project's hook, watching semantically
related ideas cluster in vector space, is exactly the exam concept it
demonstrates: embeddings plus vector similarity search. The infrastructure is
serious; the data is set dressing.

**Safety framing:** the corpus is labelled as satire and fiction, kept obviously
absurd (cryptid and lizard-people tier), and must not include content that maps
onto real-world health, election, or violence misinformation. This is a design
constraint, not a disclaimer, and it is restated in the corpus section.

**Goal:** assemble the weeks 1-9 services into one working system, and double as
exam review. The integration work connects the isolated labs and is itself the
most effective revision.

**Non-goal:** no LLM answer generation. That is AI-103 territory. Azure OpenAI is
used here only as an embeddings endpoint, never to generate answers.

---

## Architecture

Two flows: a write path that ingests theories and a read path that serves
queries.

### Write path (ingestion)

```text
Blob Storage (theory .txt lands)
  → Event Grid (blob-created event)
    → Service Bus (queue, with dead-letter queue)
      → Azure Function (chunk + embed + upsert)
        → calls Azure OpenAI for embeddings
        → writes to the vector store
```

A theory `.txt` file landing in Blob Storage raises a blob-created event on Event
Grid, which is delivered to a Service Bus queue (backed by a dead-letter queue for
poison messages). An Azure Function drains the queue, chunks and embeds each
theory by calling Azure OpenAI, and upserts the result into the vector store.

### Read path (query)

```text
GET /connect?theory=...
  → Retrieval API (FastAPI on Container Apps)
    → embeds the query via Azure OpenAI
    → runs vector similarity search against the store
    → returns ranked related theories
```

A query hits the FastAPI retrieval service running on Container Apps. The service
embeds the query text via Azure OpenAI, runs a vector similarity search against
the store, and returns the ranked related theories.

### Cross-cutting concerns

- **Key Vault** holds all connection strings and the embeddings key.
- **App Configuration** holds feature flags: the active vector store, chunk size,
  and similarity threshold.
- **OpenTelemetry** traces a request across the API, store, and Function hops.
- **KQL** queries the emitted traces.

---

## Service-to-exam-domain mapping

Every service below is built as a standalone lab in weeks 1-9 first, then wired
together here.

| Service | Role in ConspiraGraph | Exam domain |
|---|---|---|
| Container Apps | hosts the retrieval API | Containers (20-25%) |
| ACR | stores the API image | Containers |
| Cosmos DB / PostgreSQL / Redis | vector store (swappable) | Data (25-30%) |
| Blob Storage | corpus landing zone | Connect & consume |
| Event Grid | fires on new blobs | Connect & consume (20-25%) |
| Service Bus | queues ingestion work, DLQ | Connect & consume |
| Azure Functions | chunk + embed + upsert worker | Connect & consume |
| Key Vault | secrets | Secure/monitor (20-25%) |
| App Configuration | feature flags | Secure/monitor |
| OpenTelemetry + KQL | tracing + log queries | Secure/monitor |
| Azure OpenAI | embeddings endpoint only | (not a study subject) |

---

## The vector store abstraction

This is the core design decision. The shipping backend is deferred, but the
interface is defined now so that weeks 4-6 each build a real implementation behind
it.

The contract, verbatim:

```python
from typing import Protocol
from dataclasses import dataclass

@dataclass
class Theory:
    id: str
    text: str
    category: str          # e.g. "cryptid", "space", "food"
    absurdity: int         # 1–5, the metadata filter field
    embedding: list[float] | None = None

@dataclass
class Match:
    theory: Theory
    score: float           # cosine similarity

class VectorStore(Protocol):
    def upsert(self, theory: Theory) -> None: ...
    def search(
        self, embedding: list[float], k: int = 5,
        category: str | None = None,      # metadata filter
        max_absurdity: int | None = None, # metadata filter
    ) -> list[Match]: ...
    def all_edges(self, threshold: float = 0.7) -> list[tuple[str, str, float]]: ...
```

Method by method, and the exam skill each exercises:

- `upsert`: the write path. Exercises "store embeddings" across all three stores.
- `search` with filters: the "RAG with metadata filter" bullet, forced into every
  backend implementation because the filter arguments are part of the contract.
- `all_edges`: powers `/graph`. This is the method where the three stores differ
  most, which makes it the interesting benchmark target.

`CosmosVectorStore`, `PostgresVectorStore`, and `RedisVectorStore` each implement
this interface in their respective week (4, 5, and 6). An App Configuration flag
selects which backend the running API instantiates. Week 10 benchmarks all three
(same query, three backends, compare latency and recall) and the shipping choice
is made then.

---

## API endpoints

| Endpoint | Purpose |
|---|---|
| `GET /connect?theory=<text>&category=<opt>&max_absurdity=<opt>` | embed input, return k related theories with scores |
| `GET /graph?threshold=<float>` | return nodes + edges (JSON) for visualization |
| `POST /add` | pin a new theory into the corpus (triggers the write path) |
| `GET /health` | existing health probe |

The `/graph` output is JSON of the form:

```json
{ "nodes": [...], "edges": [[id_a, id_b, score], ...] }
```

The default visualization scope is a single static viewer page: one HTML file
using a force-directed graph library from a CDN. This can be dialled up to a
fuller interactive piece later, but that is out of scope for the core build.

---

## Corpus

- A few hundred short satirical theory blurbs, each tagged with `category` and
  `absurdity` (1-5).
- Source: generated, then hand-curated for tone and to enforce the satire and
  absurdity constraint.
- Stored as `.txt` or `.jsonl` in `assets/corpus/`.

Constraint restated: the corpus is labelled as satire and fiction, kept obviously
absurd (cryptid and lizard-people tier), and must not include content that maps
onto real-world health, election, or violence misinformation. Curation enforces
this before anything is committed.

---

## Weeks 10-13 build order (draft)

- **Week 10:** scaffold `projects/conspiragraph/`, implement the three
  `VectorStore` backends behind the interface, benchmark them, pick the shipping
  store, and seed the corpus.
- **Week 11:** build the ingestion pipeline (Blob to Event Grid to Service Bus to
  Function) and wire the write path end to end.
- **Week 12:** build the retrieval API (`/connect`, `/graph`, `/add`), deploy to
  Container Apps, and wire Key Vault plus App Configuration.
- **Week 13:** OpenTelemetry tracing and KQL dashboards, the `/graph` viewer, an
  end-to-end test, the portfolio README, and exam review.

---

## Budget

**Design principle:** every service scales to zero or sits in a free tier, because
the project runs for four weeks and cannot be torn down nightly.

Per-service idle cost:

| Service | Idle cost approach |
|---|---|
| Container Apps | scale to zero, $0 |
| Azure Functions | consumption grant, $0 |
| Blob Storage | free tier / per-op pennies |
| Event Grid | free tier / per-op pennies |
| Service Bus | free tier / per-op pennies |
| Key Vault | free tier / per-op pennies |
| App Configuration | free tier / per-op pennies |
| Cosmos DB | free tier or serverless |
| PostgreSQL | stoppable: stop between sessions, storage-only when stopped |
| Redis | no cheap idle: build, benchmark, delete rather than keep running |
| Azure OpenAI embeddings | usage-billed, negligible |

**AKS note:** AKS is learned in week 3 but is not the project host. AKS nodes bill
continuously with no scale-to-zero. If AKS appears in the portfolio at all, it is
a one-off documented deploy, deleted the same day.

**Estimate:** a realistic four-week run costs a few dollars, well within the $50
annual budget. All figures here are estimates.

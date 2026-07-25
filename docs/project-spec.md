# End-to-end project (weeks 10-13) — DRAFT

Target: a containerised Python retrieval service, backed by a vector store, fed by
an event-driven ingestion pipeline, secured with Key Vault, observed with
OpenTelemetry.

Services (all exam-relevant, all built as labs in weeks 1-9 first):

- Container Apps or AKS — hosts the retrieval service (weeks 2-3)
- Cosmos DB for NoSQL and/or PostgreSQL/pgvector — vector store (weeks 4-5)
- Azure Managed Redis — cache + vector index (week 6)
- Service Bus + Event Grid — ingestion pipeline (week 7)
- Azure Functions — serverless processing (week 7)
- Key Vault + App Configuration — secrets/config (week 8)
- OpenTelemetry + KQL — observability (week 9)
- Azure OpenAI — embeddings endpoint only (usage-billed, not a study subject)

Each week's lab should be built so its output can feed this final system rather
than standing alone. Full spec to be written before week 4.

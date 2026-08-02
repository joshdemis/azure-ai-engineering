# Labs

Hands-on labs, one folder per Microsoft Learn path. Each lab is self-contained and
documented so it can be re-run from scratch.

## How to Use

- Each lab folder contains a `README.md` following the
  [lab documentation template](TEMPLATE.md).
- Numbering matches the nine learning paths in
  [`../docs/roadmap.md`](../docs/roadmap.md), so lab `NN` is path `NN`.
- Work labs in numeric order; later labs build on earlier ones.
- Link each lab back to its note in [`../notes/`](../notes/) and to the objectives it
  covers in [`../docs/exam-objectives.md`](../docs/exam-objectives.md).

## Lab Index

| #  | Lab | Learning path | Services | Status |
| -- | --- | ------------- | -------- | ------ |
| 01 | [Container hosting](01-container-hosting/) | Implement container application hosting | ACR, App Service | ☑ |
| 02 | [Container Apps](02-container-apps/) | Deploy and manage apps on Azure Container Apps | Container Apps | ☑ |
| 03 | [AKS](03-aks/) | Deploy and monitor applications on AKS | AKS | ◐ module 1 of 2 |
| 04 | [Cosmos DB](04-cosmosdb/) | Develop AI solutions with Cosmos DB for NoSQL | Cosmos DB | ☐ |
| 05 | [PostgreSQL](05-postgresql/) | Develop AI solutions with Azure Database for PostgreSQL | PostgreSQL | ☐ |
| 06 | [Redis](06-redis/) | Enhance AI solutions with Azure Managed Redis | Azure Managed Redis | ☐ |
| 07 | [Backend services](07-backend-services/) | Integrate backend services for AI solutions | Service Bus, Event Grid, Functions | ☐ |
| 08 | [Secrets and config](08-secrets-config/) | Manage application secrets and configuration | Key Vault, App Configuration | ☐ |
| 09 | [Observability](09-observability/) | Observe and troubleshoot applications on Azure | OpenTelemetry, Azure Monitor, KQL | ☐ |
| 10 | [ConspiraGraph](10-project-conspiragraph/) | Project build, weeks 10-13 | Combined | ☐ |

The folder scaffolds inherited from the earlier plan still carry their old lab numbers
in their `README.md` titles. Those titles are corrected as each path is started.

# Azure AI Engineering

> A long-term, hands-on learning journey into building, deploying, and operating
> AI systems on Microsoft Azure — anchored by the **Microsoft AI-200** certification
> and designed to keep growing well beyond it.

[![Certification](https://img.shields.io/badge/Cert-Microsoft%20AI--200-0078D4)](https://learn.microsoft.com/en-us/credentials/)
[![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)]()
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Repository Purpose

This repository is a **living knowledge base and engineering portfolio** for Azure AI
work. It brings together study notes, hands-on labs, reference architectures, and
end-to-end projects in a single, version-controlled place.

It exists to:

- Track structured preparation for the **Microsoft AI-200** exam.
- Capture reproducible labs for each core Azure AI service.
- Document architectural decisions and trade-offs like a real engineering team would.
- Grow into a durable reference that outlives any single certification.

---

## Learning Philosophy

- **Build to understand.** Every concept is reinforced with a hands-on lab.
- **Document as you go.** If it isn't written down, it wasn't really learned.
- **Reproducibility first.** Infrastructure and steps should be re-runnable.
- **Architecture over syntax.** Focus on *why*, not just *how*.
- **Small, consistent increments.** Steady weekly progress beats cramming.
- **Production mindset.** Treat labs and projects as if they were going to be shipped.

---

## Current Certification Goal

| Item             | Detail                                             |
| ---------------- | -------------------------------------------------- |
| Certification    | Microsoft AI-200                                   |
| Primary goal     | Pass the exam with genuine, applied understanding  |
| Target date      | _TBD_                                              |
| Current phase    | _Foundations / Setup_                             |

See [`docs/exam-objectives.md`](docs/exam-objectives.md) and
[`docs/study-plan.md`](docs/study-plan.md) for the detailed breakdown.

---

## Study Workflow

A repeatable weekly loop:

1. **Plan** — pick objectives for the week from [`docs/study-plan.md`](docs/study-plan.md).
2. **Learn** — work through official docs, courses, and reference material.
3. **Lab** — complete the matching hands-on lab under [`labs/`](labs/).
4. **Document** — capture findings in a weekly note under [`notes/`](notes/).
5. **Decide** — record any notable design choices as an ADR in
   [`architecture/decision-records/`](architecture/decision-records/).
6. **Review** — update the progress checklist and log weak topics in
   [`exam/weak-topics.md`](exam/weak-topics.md).

---

## Project Roadmap

High-level phases. Detailed roadmap lives in [`docs/roadmap.md`](docs/roadmap.md).

- [ ] **Phase 1 — Foundations:** Azure AI Foundry, Azure OpenAI, environment setup.
- [ ] **Phase 2 — Core services:** Prompt flow, AI Search, agents, document intelligence.
- [ ] **Phase 3 — Platform & data:** Containers, Key Vault, databases, messaging.
- [ ] **Phase 4 — Operations:** Monitoring, scaling, AKS.
- [ ] **Phase 5 — Capstone projects:** Chatbot, enterprise RAG, AI agent.
- [ ] **Phase 6 — Exam readiness:** Revision, practice exams, weak-topic drilling.

---

## Progress Checklist

### AI-200 13-Week Roadmap

Week-by-week plan for the AI-200 milestone. See [`labs/`](labs/) for the
matching lab write-ups and [`notes/`](notes/) for the weekly notes.

| Week | Learning path | Service focus | Status |
| ---- | ------------- | ------------- | ------ |
| 1 | Implement container application hosting | Azure Container Registry | Done |
| 2 | Implement container application hosting | App Service (containers) | Pending |
| 3 | Deploy and manage apps on Azure Container Apps | Container Apps | Pending |
| 4 | Deploy and manage apps on Azure Container Apps | KEDA scaling | Pending |
| 5 | Deploy and monitor applications on AKS | AKS | Pending |
| 6 | Develop AI solutions with Cosmos DB for NoSQL | Cosmos DB | Pending |
| 7 | Develop AI solutions with Azure Database for PostgreSQL | PostgreSQL | Pending |
| 8 | Develop AI solutions with Azure Database for PostgreSQL | pgvector / RAG | Pending |
| 9 | Enhance AI solutions with Azure Managed Redis | Redis | Pending |
| 10 | Integrate backend services for AI solutions | Service Bus, Event Grid | Pending |
| 11 | Integrate backend services for AI solutions | Azure Functions | Pending |
| 12 | Manage secrets & config + Observe and troubleshoot | Key Vault, App Config, OTel, KQL | Pending |
| 13 | End-to-end wiring and review | Capstone review | Pending |

### Labs

- [ ] 01 — AI Foundry
- [ ] 02 — Azure OpenAI
- [ ] 03 — Prompt Flow
- [ ] 04 — AI Search
- [ ] 05 — Agents
- [ ] 06 — Document Intelligence
- [ ] 07 — Container Registry
- [ ] 08 — Container Apps
- [ ] 09 — Key Vault
- [ ] 10 — PostgreSQL
- [ ] 11 — Cosmos DB
- [ ] 12 — Redis
- [ ] 13 — Service Bus
- [ ] 14 — Monitoring
- [ ] 15 — AKS

### Projects

- [ ] Chatbot
- [ ] Enterprise RAG
- [ ] AI Agent

### Exam Readiness

- [ ] Objectives reviewed
- [ ] All labs completed
- [ ] Practice exams passed consistently
- [ ] Weak topics closed out
- [ ] Exam-day checklist prepared

---

## Technologies To Be Learned

> Placeholder inventory — deepened as the journey progresses.

**AI & ML**
- Azure AI Foundry
- Azure OpenAI Service
- Prompt Flow
- Azure AI Search
- Azure AI Agents
- Azure AI Document Intelligence

**Platform & Compute**
- Azure Container Registry
- Azure Container Apps
- Azure Kubernetes Service (AKS)
- Azure Key Vault

**Data & Messaging**
- Azure Database for PostgreSQL
- Azure Cosmos DB
- Azure Cache for Redis
- Azure Service Bus

**Operations**
- Azure Monitor / Application Insights
- Observability & logging
- Cost management

**Engineering Practices**
- Infrastructure as Code (Bicep, Terraform)
- CI/CD
- Architecture decision records

---

## Future Expansion

This repository is intentionally open-ended. Beyond AI-200, it is expected to grow into:

- Additional Azure certifications (e.g., advanced AI / architecture tracks).
- Deeper MLOps and LLMOps practices.
- Production-grade reference architectures.
- Reusable infrastructure modules under [`infra/`](infra/).
- A portfolio of increasingly ambitious projects under [`projects/future/`](projects/future/).

---

## Repository Structure

```text
azure-ai-engineering/
├── docs/           # Roadmap, study plan, exam objectives, reference material
├── notes/          # Weekly learning notes
├── labs/           # Hands-on labs, one folder per Azure AI service
├── projects/       # End-to-end capstone projects
├── architecture/   # Diagrams and architecture decision records (ADRs)
├── scripts/        # Helper and automation scripts
├── infra/          # Infrastructure as Code (Bicep, Terraform)
├── assets/         # Images and diagram source files
└── exam/           # Revision notes, weak topics, practice tracking, checklist
```

---

## License

Released under the [MIT License](LICENSE).

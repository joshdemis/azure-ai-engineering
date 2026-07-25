# Roadmap

> Long-term, phase-based plan for the Azure AI Engineering journey.
> Certification is a milestone, not the finish line.

_Last updated: 2026-07-25_

---

## Overview

<!-- Short narrative describing where the journey is now and where it is headed. -->

---

## AI-200 13-week plan

The AI-200 milestone runs on a 13-week plan at 6-8 hours per week, with the exam
booked for 18 Oct 2026. The 13 weeks split into two blocks:

- **Weeks 1-9: learning-path content.** All 9 official Microsoft Learn paths
  (24 modules, roughly 32 hours) complete here.
- **Weeks 10-13: end-to-end project build.** No new learning-path content. This
  block wires the isolated labs into a single system and doubles as exam review.

| Week | Learning path | Modules | Exam domain | Status |
| ---- | ------------- | ------- | ----------- | ------ |
| 1 | Implement container application hosting on Azure | 2 | Containers (20-25%) | Complete |
| 2 | Deploy and manage apps on Azure Container Apps | 3 | Containers | In progress |
| 3 | Deploy and monitor applications on Azure Kubernetes Service | 3 | Containers | Pending |
| 4 | Develop AI solutions with Azure Cosmos DB for NoSQL | 3 | Data (25-30%) | Pending |
| 5 | Develop AI solutions with Azure Database for PostgreSQL | 3 | Data | Pending |
| 6 | Enhance AI solutions with Azure Managed Redis | 3 | Data | Pending |
| 7 | Integrate backend services for AI solutions | 3 | Connect & consume (20-25%) | Pending |
| 8 | Manage application secrets and configuration for AI solutions | 2 | Secure/monitor (20-25%) | Pending |
| 9 | Observe and troubleshoot apps on Azure | 2 | Secure/monitor | Pending |
| 10 | Project build — phase 1 | — | — | Pending |
| 11 | Project build — phase 2 | — | — | Pending |
| 12 | Project build — phase 3 | — | — | Pending |
| 13 | Project build — phase 4 + exam review | — | — | Pending |

### Notes

- All 9 learning paths (24 modules, roughly 32 hours of content) complete in
  weeks 1-9.
- Weeks 4-7 are the heaviest: three three-module data paths plus the
  backend-services path, roughly 17 hours of content across four weeks, covering
  about 55% of exam weight combined (data 25-30% plus connect/consume 20-25%).
  Lab depth in these weeks is not to be sacrificed for project time.
- Weeks 8-9 are lighter (2-module paths) and absorb any overflow from weeks 4-7.
- The project weeks double as exam review. The integration work connects the
  isolated labs and is itself the most effective revision. The project is study,
  not separate from it.

### Path-to-week mapping

A learning path is not the same as a week. Microsoft Learn ships 9 official paths,
but the plan spans 13 weeks, so the paths map unevenly onto the calendar.

- **One path per week (weeks 1-9).** Each of the 9 paths gets its own week. Path
  length varies (2 or 3 modules), so weekly load varies rather than the paths
  spilling across week boundaries.
- **Heaviest block: weeks 4-7.** The three-module data paths (Cosmos DB,
  PostgreSQL, Managed Redis) and the backend-services path land back to back.
  This is where most of the lab depth lives.
- **Lighter block: weeks 8-9.** The two secure/monitor paths are two modules
  each and act as a buffer for overflow from the heavy block.
- **No paths in weeks 10-13.** These are reserved for the project build, which is
  where the isolated labs get connected end to end.

### Naming correction

Earlier drafts mislabelled the container paths. Container Apps was labelled week 3
and AKS was labelled week 5, which left phantom gaps in the numbering. The
corrected mapping is:

- Container Apps = week 2 (was week 3)
- AKS = week 3 (was week 5)

Lab folders under `labs/` use their own service-based numbering and are separate
from the week numbers above; they were not affected by this correction.

---

## Phase 1 — Foundations

**Goal:** _TBD_

- [ ] Environment and tooling setup
- [ ] Azure AI Foundry basics
- [ ] Azure OpenAI basics

---

## Phase 2 — Core AI Services

**Goal:** _TBD_

- [ ] Prompt flow
- [ ] AI Search
- [ ] Agents
- [ ] Document Intelligence

---

## Phase 3 — Platform & Data

**Goal:** _TBD_

- [ ] Containers (Registry, Apps)
- [ ] Key Vault
- [ ] Databases (PostgreSQL, Cosmos DB, Redis)
- [ ] Messaging (Service Bus)

---

## Phase 4 — Operations

**Goal:** _TBD_

- [ ] Monitoring & observability
- [ ] AKS

---

## Phase 5 — Capstone Projects

**Goal:** _TBD_

- [ ] Chatbot
- [ ] Enterprise RAG
- [ ] AI Agent

---

## Phase 6 — Exam Readiness

**Goal:** _TBD_

- [ ] Full objective review
- [ ] Practice exams
- [ ] Weak-topic remediation

---

## Beyond Certification

<!-- Placeholder for post-AI-200 goals: advanced certs, MLOps, portfolio growth. -->

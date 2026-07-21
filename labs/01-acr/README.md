# Lab 01 - Azure Container Registry

Week 1 lab. Build and store a container image for the `retrieval-api` app in a
private Azure Container Registry, without a local Docker install.

> Note: this lab uses the 13-week roadmap numbering (see the root
> [`README.md`](../../README.md)). The repo also carries an earlier 15-lab
> scaffold where the registry lab is
> [`labs/07-container-registry/`](../07-container-registry/). This folder holds
> the Week 1 write-up.

## Objective

Create a private registry, build a FastAPI image in the cloud, and demonstrate
the difference between mutable tags and immutable digests.

## Services used

- Azure Container Registry (SKU Basic, `acrai200dev`)
- ACR Tasks (quick task via `az acr build`, cloud-side image build)

## Exam domain

Develop containerized solutions on Azure (20-25%).

## Outcome

- Resource group `rg-ai200-dev` and registry `acrai200dev`, later migrated to
  `swedencentral` (the roadmap standard region, see
  [`../../docs/environment.md`](../../docs/environment.md)).
- Registry secured with `adminUserEnabled: false` and
  `anonymousPullEnabled: false`.
- `retrieval-api` image built in the cloud with `az acr build`, no local Docker.
- Tags `v1`, `v2`, and `latest` pushed to show mutable tags against immutable
  digests.
- Two errors hit and resolved: `RequestDisallowedByAzure` (region) and
  `MissingSubscriptionRegistration` (provider). Both logged in
  [`../../docs/troubleshooting.md`](../../docs/troubleshooting.md).

## Commands

The commands run for this lab are recorded in the weekly note (see below). A
`commands.sh` reference script for this lab is _TBD_.

## References

- Theory and full write-up: [`../../notes/week-01.md`](../../notes/week-01.md)
- Environment and naming rules: [`../../docs/environment.md`](../../docs/environment.md)
- Cost tracking: [`../../docs/cost-matrix.md`](../../docs/cost-matrix.md)

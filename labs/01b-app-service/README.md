# Lab 01b - Deploy a container to Azure App Service

Week 1 lab, module 2. Run the `retrieval-api` container image (built in
[`../01-acr/`](../01-acr/)) on Azure App Service, pulling from the private
registry with a managed identity.

## Objective

Deploy the container from ACR to an App Service web app, authenticate the pull
with a system-assigned managed identity scoped to `AcrPull`, and get the app
serving over HTTPS.

## Services used

- Azure App Service plan (F1 first, upgraded to B1)
- Azure App Service web app (container)
- Azure Container Registry (`acrai200dev`, pull source)
- Entra ID managed identity + `AcrPull` role assignment

## Exam domain

Develop containerized solutions on Azure (20-25%). The managed-identity pull and
the tier/quota behaviour also map to Secure, monitor, and troubleshoot Azure
solutions (20-25%).

## Outcome

- Web app created in `swedencentral` on a B1 plan (`asp-ai200-dev`).
- Image pulled from ACR using a system-assigned managed identity plus `AcrPull`
  scoped to the registry, with `acrUseManagedIdentityCreds = true`.
- `WEBSITES_PORT` set to 8000 to match the uvicorn bind port.
- Three errors hit and resolved: zero App Service VM quota in `northeurope`
  (moved to `swedencentral`), HTTP 503 from an unauthenticated pull, and HTTP 403
  with state `QuotaExceeded` on F1. All logged in
  [`../../docs/troubleshooting.md`](../../docs/troubleshooting.md).
- Plan deleted the same day to stop billing.

## References

- Theory and full write-up: [`../../notes/week-01.md`](../../notes/week-01.md)
  (Module 2 and the Week 1 troubleshooting log)
- Environment, region, and quota rules:
  [`../../docs/environment.md`](../../docs/environment.md)
- Cost tracking: [`../../docs/cost-matrix.md`](../../docs/cost-matrix.md)
- Registry lab (image source): [`../01-acr/`](../01-acr/)

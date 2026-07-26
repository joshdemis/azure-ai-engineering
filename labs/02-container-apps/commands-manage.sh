#!/usr/bin/env bash
#
# Week 2, module 2 — Manage containers in Azure Container Apps
#
# WARNING: run this as a script (`bash commands-manage.sh`), or strip the `#` comment
# lines when pasting interactively. Pasting a block containing `#` lines into an
# interactive zsh session evaluates the comment text, producing cosmetic
# "command not found: #" and "zsh: number expected" errors. The `az` commands still
# run; the noise is harmless but confusing. This happened repeatedly during this
# session, hence the warning.
#
# Revision names below (ca-retrieval-api--0000004, --0000005) are Azure-generated and
# will differ on a re-run. Read the real names from `revision list` first.
#
# Do not paste real GUIDs into this file. IDs (subscription, tenant, principal) stay in
# shell variables or are redacted.
#
# Prerequisite: module 1 (./commands.sh) has been run, so ca-retrieval-api exists in
# rg-ai200-dev, pulls acrai200dev.azurecr.io/retrieval-api:v2 with its managed identity,
# and serves /health on port 8000.
#
# Two steps are not fully unattended:
#   1. The `--yaml app.yaml` apply needs app.yaml edited by hand first (tcpSocket →
#      httpGet) between the export and the apply.
#   2. The 0.25 CPU + 2Gi command is meant to FAIL. Under `set -e` it aborts the
#      script, which is why it sits at the end.
# app.yaml is a local working file containing real subscription/tenant/principal IDs.
# It is git-ignored and must not be committed.

set -euo pipefail

# Switch to multiple revision mode so more than one revision can be live at once (does NOT split traffic by itself)
az containerapp revision set-mode --name ca-retrieval-api --resource-group rg-ai200-dev --mode multiple

# Create a visibly different revision by bumping the version string (template change → new revision)
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --set-env-vars APP_VERSION=0.5.0-canary

# List revisions and current traffic weights
az containerapp revision list --name ca-retrieval-api --resource-group rg-ai200-dev --all --query "[?properties.active].{name:name, traffic:properties.trafficWeight}" -o table

# Pin 100% to the current revision BY NAME — this is the step that freezes traffic and arms the 0%-canary behaviour
az containerapp ingress traffic set --name ca-retrieval-api --resource-group rg-ai200-dev --revision-weight ca-retrieval-api--0000004=100

# Deploy again — with traffic pinned by name, the new revision arrives LIVE at 0%
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --set-env-vars APP_VERSION=0.7.0-canary

# Dial a 90/10 canary split
az containerapp ingress traffic set --name ca-retrieval-api --resource-group rg-ai200-dev --revision-weight ca-retrieval-api--0000004=90 ca-retrieval-api--0000005=10

# Watch the split over 20 requests — expect ~18 stable, ~2 canary (statistical, not exact)
FQDN=$(az containerapp show -n ca-retrieval-api -g rg-ai200-dev --query properties.configuration.ingress.fqdn -o tsv)
for i in $(seq 1 20); do curl -s https://$FQDN/health | grep -o '"version":"[^"]*"'; done

# Instant rollback — 100% back to stable, canary to 0% (canary keeps running, re-promotable)
az containerapp ingress traffic set --name ca-retrieval-api --resource-group rg-ai200-dev --revision-weight ca-retrieval-api--0000004=100 ca-retrieval-api--0000005=0

# Export the full app spec to YAML — the declarative form of everything built imperatively
az containerapp show --name ca-retrieval-api --resource-group rg-ai200-dev --output yaml > app.yaml

# After editing probes in app.yaml (convert tcpSocket → httpGet path:/health), apply it (template change → new revision)
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --yaml app.yaml

# Verify what ACTUALLY applied — expect httpGet + path:/health on all three probes, not tcpSocket
az containerapp show --name ca-retrieval-api --resource-group rg-ai200-dev --query "properties.template.containers[0].probes" -o yaml

# Right-size to the smallest pairing — 0.25 vCPU locks to 0.5 GiB (1:2 ratio)
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --cpu 0.25 --memory 0.5Gi

# Deliberately break the ratio (0.25 CPU + 2Gi) — expect rejection, proves the constraint is real
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --cpu 0.25 --memory 2Gi

# List installed CLI extensions + versions (containerapp is a preview extension — hence the "behavior altered by extension" warning on every command)
az extension list --query "[].{name:name, version:version}" -o table
az version

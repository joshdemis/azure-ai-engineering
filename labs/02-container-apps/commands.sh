#!/usr/bin/env bash
#
# Week 2, module 1 — Deploy containers to Azure Container Apps
#
# Run this as a script, or strip the comment lines when pasting interactively.
# Pasting `#` comment lines into zsh throws cosmetic "command not found" and
# "number expected" errors (the `#` and the words after it get evaluated). The
# commands still run; the noise is harmless but confusing. This actually happened
# during the lab, hence the warning.
#
# IDs (subscription, tenant, principal) are captured into shell variables below
# and never hard-coded. Do not paste real GUIDs into this file.

set -euo pipefail

# Pre-flight: check regional vCPU quota before provisioning compute (habit after the week-1 App Service quota block)
az vm list-usage --location swedencentral --query "[?contains(localName,'Total Regional')].{Name:localName,Used:currentValue,Limit:limit}" -o table

# Install the Container Apps CLI extension (ships as preview — the "no stable version" message is expected, not an error)
az extension add --name containerapp --upgrade

# Register the required providers — Microsoft.App for Container Apps, OperationalInsights for the Log Analytics workspace the environment needs
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

# Create the environment — provisions the shared VNet + Log Analytics workspace
az containerapp env create --name cae-ai200-dev --resource-group rg-ai200-dev --location swedencentral --tags Environment=Learning Project=AI-200 Week=02

# List the resource group — expect ACR, the environment, AND an auto-created Log Analytics workspace
az resource list -g rg-ai200-dev --query "[].{name:name, type:type}" -o table

# Create the app with a public placeholder image first — proves environment + ingress work before introducing private-registry auth
az containerapp create --name ca-retrieval-api --resource-group rg-ai200-dev --environment cae-ai200-dev --image mcr.microsoft.com/k8se/quickstart:latest --target-port 80 --ingress external --min-replicas 0 --max-replicas 3 --tags Environment=Learning Project=AI-200 Week=02

# Get the public FQDN and hit it — expect the Azure quickstart placeholder page
FQDN=$(az containerapp show -n ca-retrieval-api -g rg-ai200-dev --query properties.configuration.ingress.fqdn -o tsv)
curl -s https://$FQDN | head -20

# 1/4 private pull: give the app a system-assigned managed identity
az containerapp identity assign --name ca-retrieval-api --resource-group rg-ai200-dev --system-assigned

# 2/4: capture the principal ID and the ACR resource ID (redact both IDs in committed notes)
PRINCIPAL_ID=$(az containerapp identity show -n ca-retrieval-api -g rg-ai200-dev --query principalId -o tsv)
ACR_ID=$(az acr show -n acrai200dev --query id -o tsv)

# 3/4: grant AcrPull — who (principal), what (AcrPull), where (this ACR only)
az role assignment create --assignee $PRINCIPAL_ID --scope $ACR_ID --role AcrPull

# 4/4: configure the app to authenticate to the registry AS its managed identity (the piece permission alone doesn't cover)
az containerapp registry set --name ca-retrieval-api --resource-group rg-ai200-dev --server acrai200dev.azurecr.io --identity system

# Swap placeholder for the real private image + inject APP_VERSION (template change → new revision)
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --image acrai200dev.azurecr.io/retrieval-api:v2 --set-env-vars APP_VERSION=0.4.0-containerapps

# Quickstart listened on 80; our uvicorn app listens on 8000 — fix ingress (app-level → no new revision)
az containerapp ingress update --name ca-retrieval-api --resource-group rg-ai200-dev --target-port 8000

# Test the private-image app — expect {"status":"ok","version":"0.4.0-containerapps"}
FQDN=$(az containerapp show -n ca-retrieval-api -g rg-ai200-dev --query properties.configuration.ingress.fqdn -o tsv)
curl -s https://$FQDN/health

# List active revisions
az containerapp revision list --name ca-retrieval-api --resource-group rg-ai200-dev --query "[].{name:name, active:properties.active, created:properties.createdTime, replicas:properties.replicas, traffic:properties.trafficWeight}" -o table

# List ALL revisions including deactivated — the old revision reappears here, scaled to zero (rollback target)
az containerapp revision list --name ca-retrieval-api --resource-group rg-ai200-dev --all --query "[].{name:name, active:properties.active, created:properties.createdTime}" -o table

# Store a secret in the app's secret store
az containerapp secret set --name ca-retrieval-api --resource-group rg-ai200-dev --secrets my-api-key=lab-placeholder-value

# Reference the secret from an env var (secretref: = pointer, not literal; template change → new revision)
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --set-env-vars EXAMPLE_KEY=secretref:my-api-key

# Shell into the running container (fails if scaled to zero — curl it awake first)
az containerapp exec --name ca-retrieval-api --resource-group rg-ai200-dev --command /bin/sh
# inside: env | grep APP_VERSION ; env | grep EXAMPLE_KEY (shows RESOLVED literal) ; ls -la /app ; ps aux ; cat /etc/os-release ; exit

# Stream container stdout/stderr live (Ctrl+C to stop); curl /health a few times to watch requests land
az containerapp logs show --name ca-retrieval-api --resource-group rg-ai200-dev --follow

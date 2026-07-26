#!/usr/bin/env bash
#
# Week 2, module 3 - Scale containers in Azure Container Apps
#
# =============================================================================
# STOP. DO NOT PASTE THIS FILE, OR ANY BLOCK OF IT, INTO AN INTERACTIVE SHELL.
# =============================================================================
#
# Run it as a script:
#
#     bash commands-scale.sh
#
# Or, if a single section must be run by hand, strip the comment lines first:
#
#     grep -v '^\s*#' commands-scale.sh | pbcopy
#
# WHY THIS WARNING IS SHOUTING. This is the THIRD session in a row that pasting
# "#" comment lines into interactive zsh has caused a failure, and it escalated
# both times:
#
#   1. Cosmetic. zsh evaluated the comment text and printed
#        command not found: #
#        zsh: number expected
#      The az commands still ran. Noisy, harmless, confusing.
#
#   2. Not cosmetic. A comment line containing an apostrophe (as in "the app is"
#      written with a possessive) was read as an UNTERMINATED SINGLE QUOTE. zsh
#      swallowed everything after it and dropped into a continuation prompt:
#
#        quote>
#
#      At that point the terminal is waiting for a closing quote, every
#      subsequent line is being buffered as string data, and no command is
#      running. Nothing after that point executed.
#
#      RECOVERY: press Ctrl+C. That aborts the buffered line and returns a
#      normal prompt. Then re-run the block properly, as a script.
#
# The failure is silent in the worst way: the shell looks like it accepted the
# paste, and half the intended commands simply never ran. Do not paste comments.
#
# As belt and braces, no comment line in this file contains an unbalanced single
# quote: the prose avoids possessives and contractions entirely, and the only
# quotes present are the balanced pair in the grep pattern above. Keep it that way
# when editing.
# =============================================================================
#
# TWO STEPS BLOCK AND ARE NOT UNATTENDED. Both "watch" commands run until Ctrl+C.
# Under "bash commands-scale.sh" the script will sit on them until interrupted,
# which is intentional: watching the replica count climb IS the observation step
# of this module. Ctrl+C moves on to the next command.
#
# Prerequisites: modules 1 and 2 (./commands.sh, ./commands-manage.sh) have been
# run, so ca-retrieval-api exists in rg-ai200-dev, pulls
# acrai200dev.azurecr.io/retrieval-api:v2 with its system-assigned managed
# identity, and serves /health on port 8000.
#
# Secrets and IDs: the storage account key is captured into a shell variable and
# never written to this file or committed. Same rule for subscription, tenant,
# and principal IDs. Redact before committing anything derived from this run.
#
# Standing cost: the storage account created here is the only resource in this
# module that bills while idle. The cleanup section at the end deletes it. Do not
# skip it.

set -euo pipefail

# ---------------------------------------------------------------------------
# HTTP scale rule: making the implicit default explicit
# ---------------------------------------------------------------------------

# Explicit HTTP scale rule - target ~10 concurrent requests per replica, range 0-5
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --min-replicas 0 --max-replicas 5 --scale-rule-name http-rule --scale-rule-type http --scale-rule-http-concurrency 10

# Move 100% to the newest revision (the one carrying the scale rule) so we can watch it scale
NEWEST=$(az containerapp revision list -n ca-retrieval-api -g rg-ai200-dev --query "[?properties.active] | [-1].name" -o tsv)
az containerapp ingress traffic set -n ca-retrieval-api -g rg-ai200-dev --revision-weight $NEWEST=100

# Watch live replica count (Ctrl+C to stop)
watch -n 2 "az containerapp replica list -n ca-retrieval-api -g rg-ai200-dev --query 'length(@)' -o tsv"

# Generate concurrent HTTP load - 50 parallel, 200 total, to push past the concurrency threshold
FQDN=$(az containerapp show -n ca-retrieval-api -g rg-ai200-dev --query properties.configuration.ingress.fqdn -o tsv)
for i in $(seq 1 200); do curl -s -o /dev/null https://$FQDN/health & done; wait

# ---------------------------------------------------------------------------
# KEDA queue scaler build
# ---------------------------------------------------------------------------

# Storage account (globally unique, lowercase alphanumeric, 3-24 chars)
STORAGE=stai200dev$RANDOM
az storage account create --name $STORAGE --resource-group rg-ai200-dev --location swedencentral --sku Standard_LRS --tags Environment=Learning Project=AI-200 Week=02

# Account key for lab setup only (queue create + message put). NOTE: master key = full account access; never commit or screenshot
STORAGE_KEY=$(az storage account keys list --account-name $STORAGE -g rg-ai200-dev --query "[0].value" -o tsv)

# Create the queue KEDA will watch
az storage queue create --name ingest --account-name $STORAGE --account-key $STORAGE_KEY

# Push 20 messages (the backlog)
for i in $(seq 1 20); do az storage message put --queue-name ingest --content "theory-$i" --account-name $STORAGE --account-key $STORAGE_KEY; done

# Read back the system-assigned identity principal for the app, and the storage scope
PRINCIPAL_ID=$(az containerapp identity show -n ca-retrieval-api -g rg-ai200-dev --query principalId -o tsv)
STORAGE_ID=$(az storage account show -n $STORAGE -g rg-ai200-dev --query id -o tsv)

# Grant ONLY queue-data read - least privilege, scoped to this storage account
az role assignment create --assignee $PRINCIPAL_ID --scope $STORAGE_ID --role "Storage Queue Data Reader"

# Queue-depth scale rule authenticated via managed identity (queueLength=5, so 20 msgs = ~4 replicas)
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --min-replicas 0 --max-replicas 10 --scale-rule-name queue-rule --scale-rule-type azure-queue --scale-rule-metadata "queueName=ingest" "accountName=$STORAGE" "queueLength=5" --scale-rule-identity system

# Watch it climb to ~4, driven purely by queue depth (independent of traffic weight)
watch -n 2 "az containerapp replica list -n ca-retrieval-api -g rg-ai200-dev --query 'length(@)' -o tsv"

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

# Reset to a simple HTTP rule so the app can fall back to zero (the queue rule held ~4 replicas on an undrained queue)
az containerapp update --name ca-retrieval-api --resource-group rg-ai200-dev --min-replicas 0 --max-replicas 3 --scale-rule-name http-rule --scale-rule-type http --scale-rule-http-concurrency 10

# Delete the storage account - the one artifact here with standing cost
az storage account delete --name $STORAGE --resource-group rg-ai200-dev --yes

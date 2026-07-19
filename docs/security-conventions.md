# Security Conventions

Redaction and handling rules for anything committed to this repository.

## Never commit

- Subscription IDs
- Tenant IDs
- Service principal secrets (client secrets)
- Connection strings
- Storage account keys
- SAS tokens
- API keys

## Redaction placeholders

Replace secrets with explicit placeholders so it is obvious a value was removed:

- `<SUBSCRIPTION_ID>`
- `<TENANT_ID>`
- `<CLIENT_SECRET>`

## Capturing evidence

- Prefer copied terminal text over screenshots. Text is greppable, diffable, and
  editable, so a leaked value can be found and removed.
- Prefer scoped CLI output over raw JSON dumps. Use `--query "{...}" -o table`
  to return only the fields needed, which reduces the chance of pasting a secret
  by accident.

## Leaks are permanent

Git history is permanent. Removing a secret in a later commit does not remove it
from history, and it may already be cloned or cached elsewhere. A leaked secret
must be rotated (regenerated and the old value invalidated), not just deleted in
a follow-up commit.

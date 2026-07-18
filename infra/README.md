# Infrastructure as Code

Reusable infrastructure definitions for provisioning Azure resources used by the
labs and projects. Two toolchains are kept side by side for learning and comparison.

## Structure

| Path | Purpose |
| ---- | ------- |
| [`bicep/`](bicep/) | Azure-native IaC using Bicep. |
| [`terraform/`](terraform/) | Multi-cloud-friendly IaC using Terraform. |

## Principles

- **Reproducible:** any environment can be recreated from code.
- **Parameterised:** no hard-coded names, regions, or secrets.
- **Least privilege:** grant only the access each resource needs.
- **Tagged:** apply consistent tags for ownership and cost tracking.
- **Cost-aware:** prefer teardown-friendly, low-cost SKUs for learning.

## Conventions

- Keep example variable files (`*.tfvars.example`, parameter samples) in git;
  keep real values out (see [`../.gitignore`](../.gitignore)).
- Document per-stack usage in the respective subfolder README.

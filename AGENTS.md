# AI Agents Guidelines

This document provides instructions for AI Agents working with the implementations of this Terraform module template.

## Template Guidelines
- **Avoid In place Modification** for implementations terraform-module-template is a template repository should not contain implementations.
- **Use Separate Repository for Implementations**: Implementations should be stored in separate repositories to maintain modularity and version control.
  - New repositories should be named in a way that reflects their purpose and functionality, prefixed with `terraform-module-` followed by the cloud provider (e.g., `terraform-module-aws`, `terraform-module-gcp`, `terraform-module-azurerm`).
  - This template repository should be used as a boilerplate for new implementations.
  - Use GitHub Flow way of work for template and implementation repositories.
- **Supported Providers**:
 - AWS
 - GCP
 - Azure
 - MongoDB Atlas
 - Github


## Implementation Repository Guidelines

- **Avoid to modify**: Avoid at all costs, do not modify `locals-vars.tf`, `variables.tf`, and any files originating from the cloud provider boilerplate (e.g., `aws.tf`, `google.tf`, `azurerm.tf`, `variables-azurerm.tf`, `locals.tf`) in `.cloudopsworks/boilerplate/` (except `versions.tf`).
- **Use variables-module.tf**:
  - Rename the word `module` in `variables-module.tf` with a proper subname depending on the purpose of this module.
  - The subname must be no more than 12 chars (e.g., `variables-vpc.tf`).
- **Initialization**:
  - This template must be initialized on the target cloud provider using `Makefile`.
  - For AWS: `make init/aws`
  - For GCP: `make init/gcp`
  - For Azure: `make init/azurerm`
  - For MongoDB Atlas: `make init/mongodb`
  - For Github: `make init/github`
  - The initialization process for each cloud will copy its boilerplate files to the root module.
  - If a `versions.tf` file exists (e.g., from `.cloudopsworks/boilerplate/aws`, `gcp`, `azurerm`, or any other supported provider), the module is already initialized and under development.
  - You can check the current provider in `.cloudopsworks/.provider`.
  - You can modify `versions.tf` to include additional providers to help with the resolution of your task.
- **Avoid creating spurious configuration files**:
    - Do not create any configuration files that are not required for the task at hand.
    - Only create files that are necessary for the specific functionality being implemented.
    - Do not create provider files or provider initialization implementation at all.
- **Locals management**:
  - Do not create local variables that are not used in the module.
  - Keep local variable names descriptive and consistent with the module's purpose.
  - Use locals to encapsulate complex expressions and improve readability.
- **Documentation**: See [Documentation Guidelines](#documentation-guidelines) section below.
- **Variables**:
  - Honor structured variables instead of lots of simple variables.
  - Prefer to have a single settings variable for simplicity and maintainability.
  - Use descriptive variable names that reflect their purpose.
  - Avoid using magic numbers and constants directly in code.
- **Mandatory Header**: Each .tf file must start with the following copyright header:
  ```hcl
  ##
  # (c) 2021-2026
  #     Cloud Ops Works LLC - https://cloudops.works/
  #     Find us on:
  #       GitHub: https://github.com/cloudopsworks
  #       WebSite: https://cloudops.works
  #     Distributed Under Apache v2.0 License
  #
  ```
- **Formatting, Validation & Linting**:
  - Formatting: `make fmt`
  - Validation & Linting: `make lint`
- **Repository Management**
  - Use process as described in the contributing guidelines: [GitHub Flow](https://cloudopsworks.co/resources/githubflow-way-of-work/)


## Versioning Management

Module versioning follows GitHub Flow — a simplified branching model where feature branches are created from and merged back into `master`. Use `make` targets whenever available for branch and release operations.

### General Rules

- **Never push directly to `master`**. All changes must flow through feature or hotfix branches and be merged via pull requests.
- Follow [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`) for all module tags.
- There is no `develop` branch — all work flows directly through feature branches to `master`. This approach simplifies the development workflow and enables continuous integration and deployment from the main branch.

### Semver Commit Annotations

To trigger the correct version bump in CI, include a semver annotation in your commit message or PR description:

| Change Type             | Annotation keywords                        |
|-------------------------|--------------------------------------------|
| Major / breaking change | `+semver: major` or `+semver: breaking`    |
| Minor / feature change  | `+semver: minor` or `+semver: feature`     |
| Fix / patch change      | `+semver: fix` or `+semver: patch`         |

Example commit messages:
```
feat: add support for VPC endpoints +semver: minor
fix: correct IAM policy ARN +semver: fix
refactor!: remove deprecated outputs +semver: breaking
```

### New Module Features and Provider Version Upgrades

All new features and provider version upgrades branch directly from `master` using the no-develop targets:

1. Create a feature branch from `master`:
   ```sh
   make gitflow/feature/start-no-develop:<feature-name>
   ```
2. Implement changes and validate:
   ```sh
   make fmt
   make lint
   ```
3. Finish the feature — this merges it back into `master` via pull request:
   ```sh
   make gitflow/feature/finish-no-develop:<feature-name>
   ```

For provider upgrades, increment the semver digit accordingly: **MAJOR** for breaking provider changes (e.g., AWS `4.x` → `5.x`), **MINOR** for backwards-compatible upgrades.

### Workflow Version Upgrades (Minor or Major)

Upgrades to the workflow version itself — whether minor or major — follow the same GitHub Flow feature branch process as any other change:

1. Create a feature branch from `master`:
   ```sh
   make gitflow/feature/start-no-develop:<feature-name>
   ```
   Use a descriptive name such as `workflow-upgrade-v2` or `github-flow-migration`.
2. Apply the workflow version changes and validate:
   ```sh
   make fmt
   make lint
   ```
3. Finish the feature — this merges it back into `master` via pull request:
   ```sh
   make gitflow/feature/finish-no-develop:<feature-name>
   ```

### Summary Table

| Change Type                              | Branch Type | Merges Into | Semver Impact | Annotation                          |
|------------------------------------------|-------------|-------------|---------------|-------------------------------------|
| Workflow version upgrade (minor/major)   | `feature`   | `master`    | PATCH / MINOR | `+semver: patch` / `+semver: minor` |
| Provider major version upgrade           | `feature`   | `master`    | MAJOR         | `+semver: major`                    |
| Provider minor/patch version upgrade     | `feature`   | `master`    | MINOR / PATCH | `+semver: minor` / `+semver: patch` |
| New module feature                       | `feature`   | `master`    | MINOR         | `+semver: feature`                  |
| Bug fix                                  | `feature`   | `master`    | PATCH         | `+semver: fix`                      |
| Breaking / incompatible change           | `feature`   | `master`    | MAJOR         | `+semver: breaking`                 |


## Documentation Guidelines

> Act as an expert documentation professional and Terraform/Terragrunt DevOps expert.
> Generated documentation must be human-legible; tables are encouraged for clarity.

- **Source file**: Documentation is maintained in `README.yaml`. Inner sections may use Markdown formatting.
- **Inline variable documentation**:
  - Complete inline documentation in `variables-module.tf` (or its renamed equivalent; there may be multiple `variables-*.tf` files).
  - Document each variable attribute in YAML format within the variable declaration block.
  - After each attribute, add a comment indicating whether it is `(Required)` or `(Optional)`, a short description, and the default value when applicable. Example:
    ```yaml
    id: "sampleid"   # (Required) Unique identifier for the resource.
    ```
  - Infer and document the possible values for each attribute using the upstream Terraform provider documentation as the source.
- **README.yaml fields**: Once inline documentation is complete, update `README.yaml` to properly document the following fields:
  - `name`
  - `description`
  - `introduction`
  - `usage` — write examples using Terragrunt HCL; avoid plain Terraform HCL. Include all module variables with their full inline-documented YAML structure.
  - `examples` and `quickstart`
- **Updates**: Apply the same criteria above whenever new variables or resources are added to the module.
- **README.md generation**: Run `make readme` as the **last step** after all documentation updates are complete.
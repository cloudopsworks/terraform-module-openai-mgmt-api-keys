## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.35 |
| <a name="requirement_openai"></a> [openai](#requirement\_openai) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.39.0 |
| <a name="provider_openai"></a> [openai](#provider\_openai) | 2.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tags"></a> [tags](#module\_tags) | cloudopsworks/tags/local | 1.0.9 |

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.admin_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.admin_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [openai_admin_api_key.this](https://registry.terraform.io/providers/mkdev-me/openai/latest/docs/resources/admin_api_key) | resource |
| [openai_project_service_account.this](https://registry.terraform.io/providers/mkdev-me/openai/latest/docs/resources/project_service_account) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_is_hub"></a> [is\_hub](#input\_is\_hub) | Is this a hub or spoke configuration? | `bool` | `false` | no |
| <a name="input_org"></a> [org](#input\_org) | Organization details | <pre>object({<br/>    organization_name = string<br/>    organization_unit = string<br/>    environment_type  = string<br/>    environment_name  = string<br/>  })</pre> | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | Settings for OpenAI API key management via service accounts and admin keys | <pre>object({<br/>    projects = optional(map(object({           # (Optional) Map keyed by a logical project name<br/>      project_id = string                      # (Required) The OpenAI project ID (e.g. "proj_xxx")<br/>      service_accounts = optional(map(object({ # (Optional) Map of service accounts keyed by logical name<br/>        name_prefix = optional(string)         # (Optional) Name prefix composed as name_prefix + "-" + system_name<br/>        name        = optional(string)         # (Optional) Fixed name for the service account<br/>        secret = optional(object({<br/>          name_prefix = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name<br/>          name        = optional(string)      # (Optional) Fixed name for the Secrets Manager secret<br/>          path        = optional(string)      # (Optional) Override the default secret path /<org_unit>/<env_name>/<env_type>/<project_key><br/>          plain       = optional(bool, false) # (Optional) Store the API key as a plain string instead of JSON {"api_key":"<value>"}. Default: false<br/>          description = optional(string)      # (Optional) Human-readable description for the Secrets Manager secret<br/>        }), {})<br/>      })), {})<br/>    })), {})<br/>    admin_keys = optional(map(object({         # (Optional) Map of org-level admin API keys keyed by logical name<br/>      name_prefix = optional(string)           # (Optional) Name prefix composed as name_prefix + "-" + system_name<br/>      name        = optional(string)           # (Optional) Fixed name for the admin API key<br/>      scopes      = optional(list(string), []) # (Optional) Permission scopes. Possible values: "users.read", "users.write", "projects.read", "projects.write", "api_keys.read", "api_keys.write", "rate_limits.read", "rate_limits.write"<br/>      expires_at  = optional(number)           # (Optional) Unix timestamp for key expiration<br/>      secret = optional(object({<br/>        name_prefix = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name<br/>        name        = optional(string)      # (Optional) Fixed name for the Secrets Manager secret<br/>        path        = optional(string)      # (Optional) Override the admin secret base path /<org_unit>/<env_name>/<env_type>; final path appends /admin/<secret_name><br/>        plain       = optional(bool, false) # (Optional) Store the API key as a plain string instead of JSON {"api_key":"<value>"}. Default: false<br/>        description = optional(string)      # (Optional) Human-readable description for the Secrets Manager secret<br/>      }), {})<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_spoke_def"></a> [spoke\_def](#input\_spoke\_def) | Spoke ID Number, must be a 3 digit number | `string` | `"001"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_key_ids"></a> [admin\_key\_ids](#output\_admin\_key\_ids) | Map of OpenAI admin API key IDs keyed by the settings.admin\_keys logical name |
| <a name="output_admin_secret_arns"></a> [admin\_secret\_arns](#output\_admin\_secret\_arns) | Map of AWS Secrets Manager secret ARNs holding admin API keys, keyed by the settings.admin\_keys logical name |
| <a name="output_admin_secret_names"></a> [admin\_secret\_names](#output\_admin\_secret\_names) | Map of AWS Secrets Manager secret names holding admin API keys, keyed by the settings.admin\_keys logical name |
| <a name="output_secret_arns"></a> [secret\_arns](#output\_secret\_arns) | Map of AWS Secrets Manager secret ARNs holding service account API keys, keyed by '<project\_key>/<service\_account\_key>' |
| <a name="output_secret_names"></a> [secret\_names](#output\_secret\_names) | Map of AWS Secrets Manager secret names holding service account API keys, keyed by '<project\_key>/<service\_account\_key>' |
| <a name="output_service_account_ids"></a> [service\_account\_ids](#output\_service\_account\_ids) | Map of OpenAI service account IDs keyed by '<project\_key>/<service\_account\_key>' |

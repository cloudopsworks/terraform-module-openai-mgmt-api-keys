## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.35 |
| <a name="requirement_openai"></a> [openai](#requirement\_openai) | >= 0.2.1, < 1.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.72.0 |
| <a name="provider_openai"></a> [openai](#provider\_openai) | 0.2.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_tags"></a> [tags](#module\_tags) | cloudopsworks/tags/local | 1.0.10 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_secretsmanager_secret.admin_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_rotation.admin_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_rotation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.admin_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.admin_rotation_bootstrap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.admin_rotation_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.rotation_bootstrap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.rotation_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [openai_admin_api_key.this](https://registry.terraform.io/providers/cloudopsworks/openai/latest/docs/resources/admin_api_key) | resource |
| [openai_service_account.rotating](https://registry.terraform.io/providers/cloudopsworks/openai/latest/docs/resources/service_account) | resource |
| [openai_service_account.this](https://registry.terraform.io/providers/cloudopsworks/openai/latest/docs/resources/service_account) | resource |
| [aws_lambda_function.rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_is_hub"></a> [is\_hub](#input\_is\_hub) | Is this a hub or spoke configuration? | `bool` | `false` | no |
| <a name="input_org"></a> [org](#input\_org) | Organization details | <pre>object({<br/>    organization_name = string<br/>    organization_unit = string<br/>    environment_type  = string<br/>    environment_name  = string<br/>  })</pre> | n/a | yes |
| <a name="input_settings"></a> [settings](#input\_settings) | Settings for OpenAI API key management via service accounts and admin keys | <pre>object({<br/>    rotation_lambda          = optional(string)     # (Optional) Lambda function name or ARN; null disables rotation<br/>    rotation_period_days     = optional(number, 30) # (Optional) Whole days, 1-999 for rate; 1000 uses legacy scheduling without an explicit window<br/>    rotation_window_hours    = optional(number)     # (Optional) Window length in whole hours, 1-23. Null uses the AWS default<br/>    rotation_cron_expression = optional(string)     # (Optional) AWS cron with one UTC start hour; overrides the rate interval<br/>    projects = optional(map(object({                # (Optional) Map keyed by a logical project name<br/>      project_id = string                           # (Required) The OpenAI project ID (e.g. "proj_xxx")<br/>      service_accounts = optional(map(object({      # (Optional) Map of service accounts keyed by logical name<br/>        name_prefix        = optional(string)       # (Optional) Name prefix composed as name_prefix + "-" + system_name<br/>        name               = optional(string)       # (Optional) Fixed name for the service account<br/>        role               = optional(string)       # (Optional) Project role for the service account. Possible values: "member", "owner". Default: "member"<br/>        scopes             = optional(set(string))  # (Optional) Project-key scopes. Default: null; changes replace the account only without rotation, otherwise update TFCONFIG<br/>        expires_in_seconds = optional(number)       # (Optional) Relative TTL for Lambda-owned project keys; null derives it from a rate schedule<br/>        secret = optional(object({<br/>          name_prefix      = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name<br/>          name             = optional(string)      # (Optional) Fixed name for the Secrets Manager secret<br/>          path             = optional(string)      # (Optional) Override the default secret path /<org_unit>/<env_name>/<env_type>/<project_key><br/>          plain            = optional(bool, false) # (Optional, deprecated) Must be false; credentials are structured JSON<br/>          description      = optional(string)      # (Optional) Human-readable description for the Secrets Manager secret<br/>          rotation_enabled = optional(bool, true)  # (Optional) Enroll in module-wide rotation. Default: true; false opts out (not recommended)<br/>        }), {})<br/>      })), {})<br/>    })), {})<br/>    admin_keys = optional(map(object({      # (Optional) Map of org-level admin API keys keyed by logical name<br/>      name_prefix        = optional(string) # (Optional) Name prefix composed as name_prefix + "-" + system_name<br/>      name               = optional(string) # (Optional) Fixed name for the admin API key<br/>      expires_in_seconds = optional(number) # (Optional) Seconds until the admin key expires. Mutually exclusive with expire_in_hours and expire_in_days. Default: null (non-expiring)<br/>      expire_in_hours    = optional(number) # (Optional) Hours until the admin key expires. Mutually exclusive with expires_in_seconds and expire_in_days. Default: null (non-expiring)<br/>      expire_in_days     = optional(number) # (Optional) Days until the admin key expires. Mutually exclusive with expires_in_seconds and expire_in_hours. Default: null (non-expiring)<br/>      secret = optional(object({<br/>        name_prefix      = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name<br/>        name             = optional(string)      # (Optional) Fixed name for the Secrets Manager secret<br/>        path             = optional(string)      # (Optional) Override the full admin secret parent path. Default: /<org_unit>/<env_name>/<env_type>/admin<br/>        plain            = optional(bool, false) # (Optional, deprecated) Must be false; credentials are structured JSON<br/>        description      = optional(string)      # (Optional) Human-readable description for the Secrets Manager secret<br/>        rotation_enabled = optional(bool, true)  # (Optional) Enroll in module-wide rotation. Default: true; false opts out (not recommended)<br/>      }), {})<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_spoke_def"></a> [spoke\_def](#input\_spoke\_def) | Spoke ID Number, must be a 3 digit number | `string` | `"001"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_admin_key_ids"></a> [admin\_key\_ids](#output\_admin\_key\_ids) | Map of Terraform-owned nonrotating OpenAI admin API key IDs keyed by the settings.admin\_keys logical name |
| <a name="output_admin_rotation_config_version_ids"></a> [admin\_rotation\_config\_version\_ids](#output\_admin\_rotation\_config\_version\_ids) | Map of Terraform-managed admin-key TFCONFIG version IDs |
| <a name="output_admin_rotation_secret_arns"></a> [admin\_rotation\_secret\_arns](#output\_admin\_rotation\_secret\_arns) | Map of admin-key Secrets Manager ARNs enrolled in Lambda-owned rotation |
| <a name="output_admin_secret_arns"></a> [admin\_secret\_arns](#output\_admin\_secret\_arns) | Map of AWS Secrets Manager secret ARNs holding admin API keys, keyed by the settings.admin\_keys logical name |
| <a name="output_admin_secret_names"></a> [admin\_secret\_names](#output\_admin\_secret\_names) | Map of AWS Secrets Manager secret names holding admin API keys, keyed by the settings.admin\_keys logical name |
| <a name="output_rotation_config_version_ids"></a> [rotation\_config\_version\_ids](#output\_rotation\_config\_version\_ids) | Map of Terraform-managed service-account TFCONFIG version IDs |
| <a name="output_rotation_secret_arns"></a> [rotation\_secret\_arns](#output\_rotation\_secret\_arns) | Map of service-account Secrets Manager ARNs enrolled in Lambda-owned rotation |
| <a name="output_secret_arns"></a> [secret\_arns](#output\_secret\_arns) | Map of AWS Secrets Manager secret ARNs holding service account API keys, keyed by '<project\_key>/<service\_account\_key>' |
| <a name="output_secret_names"></a> [secret\_names](#output\_secret\_names) | Map of AWS Secrets Manager secret names holding service account API keys, keyed by '<project\_key>/<service\_account\_key>' |
| <a name="output_service_account_api_key_ids"></a> [service\_account\_api\_key\_ids](#output\_service\_account\_api\_key\_ids) | Map of Terraform-owned, nonrotating service-account API key IDs; rotating keys are Lambda-owned |
| <a name="output_service_account_bootstrap_api_key_ids"></a> [service\_account\_bootstrap\_api\_key\_ids](#output\_service\_account\_bootstrap\_api\_key\_ids) | Deprecated compatibility output: rotating accounts create no bootstrap key, so values are null; historical state may contain retired key IDs |
| <a name="output_service_account_ids"></a> [service\_account\_ids](#output\_service\_account\_ids) | Map of OpenAI service account IDs keyed by '<project\_key>/<service\_account\_key>' |

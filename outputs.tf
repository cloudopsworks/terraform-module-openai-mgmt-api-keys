##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "service_account_ids" {
  description = "Map of OpenAI service account IDs keyed by '<project_key>/<service_account_key>'"
  value = {
    for k, v in local.service_account_resources : k => v.id
  }
}

output "service_account_api_key_ids" {
  description = "Map of Terraform-owned, nonrotating service-account API key IDs; rotating keys are Lambda-owned"
  value = {
    for k, v in openai_service_account.this : k => v.api_key_id
  }
}

output "service_account_bootstrap_api_key_ids" {
  description = "Deprecated compatibility output: rotating accounts create no bootstrap key, so values are null; historical state may contain retired key IDs"
  value = {
    for k, v in openai_service_account.rotating : k => v.api_key_id
  }
}

output "secret_arns" {
  description = "Map of AWS Secrets Manager secret ARNs holding service account API keys, keyed by '<project_key>/<service_account_key>'"
  value = {
    for k, v in aws_secretsmanager_secret.this : k => v.arn
  }
}

output "secret_names" {
  description = "Map of AWS Secrets Manager secret names holding service account API keys, keyed by '<project_key>/<service_account_key>'"
  value = {
    for k, v in aws_secretsmanager_secret.this : k => v.name
  }
}

output "admin_key_ids" {
  description = "Map of Terraform-owned nonrotating OpenAI admin API key IDs keyed by the settings.admin_keys logical name"
  value = {
    for k, v in openai_admin_api_key.this : k => v.id
  }
}

output "rotation_secret_arns" {
  description = "Map of service-account Secrets Manager ARNs enrolled in Lambda-owned rotation"
  value = {
    for k, v in aws_secretsmanager_secret.this : k => v.arn
    if contains(keys(local.rotating_service_accounts), k)
  }
}

output "rotation_config_version_ids" {
  description = "Map of Terraform-managed service-account TFCONFIG version IDs"
  value = {
    for k, v in aws_secretsmanager_secret_version.rotation_config : k => v.version_id
  }
}

output "admin_rotation_secret_arns" {
  description = "Map of admin-key Secrets Manager ARNs enrolled in Lambda-owned rotation"
  value = {
    for k, v in aws_secretsmanager_secret.admin_key : k => v.arn
    if contains(keys(local.rotating_admin_keys), k)
  }
}

output "admin_rotation_config_version_ids" {
  description = "Map of Terraform-managed admin-key TFCONFIG version IDs"
  value = {
    for k, v in aws_secretsmanager_secret_version.admin_rotation_config : k => v.version_id
  }
}

output "admin_secret_arns" {
  description = "Map of AWS Secrets Manager secret ARNs holding admin API keys, keyed by the settings.admin_keys logical name"
  value = {
    for k, v in aws_secretsmanager_secret.admin_key : k => v.arn
  }
}

output "admin_secret_names" {
  description = "Map of AWS Secrets Manager secret names holding admin API keys, keyed by the settings.admin_keys logical name"
  value = {
    for k, v in aws_secretsmanager_secret.admin_key : k => v.name
  }
}

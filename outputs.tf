##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "service_account_ids" {
  description = "Map of OpenAI service account IDs keyed by the settings.service_accounts map key"
  value = {
    for k, v in openai_project_service_account.this : k => v.service_account_id
  }
}

output "secret_arns" {
  description = "Map of AWS Secrets Manager secret ARNs holding the API keys, keyed by the settings.service_accounts map key"
  value = {
    for k, v in aws_secretsmanager_secret.this : k => v.arn
  }
}

output "secret_names" {
  description = "Map of AWS Secrets Manager secret names holding the API keys, keyed by the settings.service_accounts map key"
  value = {
    for k, v in aws_secretsmanager_secret.this : k => v.name
  }
}

output "admin_key_ids" {
  description = "Map of OpenAI admin API key IDs keyed by the settings.admin_keys map key"
  value = {
    for k, v in openai_admin_api_key.this : k => v.id
  }
}

output "admin_secret_arns" {
  description = "Map of AWS Secrets Manager secret ARNs holding the admin API keys, keyed by the settings.admin_keys map key"
  value = {
    for k, v in aws_secretsmanager_secret.admin_key : k => v.arn
  }
}

output "admin_secret_names" {
  description = "Map of AWS Secrets Manager secret names holding the admin API keys, keyed by the settings.admin_keys map key"
  value = {
    for k, v in aws_secretsmanager_secret.admin_key : k => v.name
  }
}

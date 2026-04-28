##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
# Stores the OpenAI service account API key in AWS Secrets Manager.
# Service account secret path: <secret_store_path>/<project_key>/<secret_name>
# Admin key secret path defaults to <secret_store_path>/admin/<secret_name>.
# If admin secret.path is set, it is used verbatim as the full parent path for <secret_name>.
# The api_key_value from the service account resource is only available at creation time.

resource "aws_secretsmanager_secret" "this" {
  for_each = local.service_accounts
  name     = "${local.secret_paths[each.key]}/${local.secret_names[each.key]}"
  tags     = local.all_tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each  = local.service_accounts
  secret_id = aws_secretsmanager_secret.this[each.key].id
  secret_string = local.secret_plain[each.key] ? (
    openai_project_service_account.this[each.key].api_key_value
    ) : (
    jsonencode({ api_key = openai_project_service_account.this[each.key].api_key_value })
  )
}

resource "aws_secretsmanager_secret" "admin_key" {
  for_each = local.admin_keys
  name     = "${local.admin_secret_paths[each.key]}/${local.admin_secret_names[each.key]}"
  tags     = local.all_tags
}

resource "aws_secretsmanager_secret_version" "admin_key" {
  for_each  = local.admin_keys
  secret_id = aws_secretsmanager_secret.admin_key[each.key].id
  secret_string = local.admin_secret_plain[each.key] ? (
    openai_admin_api_key.this[each.key].api_key_value
    ) : (
    jsonencode({ api_key = openai_admin_api_key.this[each.key].api_key_value })
  )
}

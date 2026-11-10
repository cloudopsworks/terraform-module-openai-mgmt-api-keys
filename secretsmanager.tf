##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Service-account identity remains Terraform-owned; Lambda creates every
# rotating project key. TFBOOTSTRAP is an unusable create-new marker.
locals {
  service_account_secret_payloads = {
    for key, account in openai_service_account.this : key => jsonencode({
      key_type           = "project"
      api_key            = account.api_key_value
      api_key_id         = account.api_key_id
      name               = account.api_key_name
      project_id         = local.service_accounts[key].project_id
      service_account_id = account.id
    })
  }

  service_account_bootstrap_payloads = {
    for key, account in local.rotating_service_accounts : key => jsonencode({
      key_type           = "project"
      api_key            = null
      api_key_id         = "__CREATE_NEW__"
      name               = local.sa_names[key]
      project_id         = account.project_id
      service_account_id = openai_service_account.rotating[key].id
    })
  }

  admin_secret_payloads = {
    for key, api_key in openai_admin_api_key.this : key => jsonencode({
      key_type           = "admin"
      api_key            = api_key.value
      api_key_id         = api_key.id
      name               = api_key.name
      project_id         = null
      service_account_id = null
    })
  }

  admin_bootstrap_payloads = {
    for key, api_key in local.rotating_admin_keys : key => jsonencode({
      api_key    = null
      api_key_id = "__CREATE_NEW__"
    })
  }

  # TFCONFIG is intentionally not a usable credential version. Terraform can
  # replace it without moving AWSCURRENT, which remains Lambda-owned.
  service_account_rotation_configs = {
    for key, account in local.rotating_service_accounts : key => jsonencode({
      schema_version     = 1
      key_type           = "project"
      name               = local.sa_names[key]
      project_id         = account.project_id
      service_account_id = openai_service_account.rotating[key].id
      scopes             = account.scopes == null ? null : sort(tolist(account.scopes))
      role               = account.role == null ? "member" : account.role
      expires_in_seconds = null
    })
  }

  admin_rotation_configs = {
    for key, api_key in local.rotating_admin_keys : key => jsonencode({
      schema_version     = 1
      key_type           = "admin"
      name               = local.admin_key_names[key]
      project_id         = null
      service_account_id = null
      scopes             = null
      role               = null
      expires_in_seconds = (
        api_key.expires_in_seconds != null ? api_key.expires_in_seconds :
        api_key.expire_in_hours != null ? api_key.expire_in_hours * 3600 :
        api_key.expire_in_days != null ? api_key.expire_in_days * 86400 : null
      )
    })
  }
}

resource "aws_secretsmanager_secret" "this" {
  for_each    = local.service_accounts
  name        = "${local.secret_paths[each.key]}/${local.secret_names[each.key]}"
  description = local.secret_descriptions[each.key]
  tags        = local.all_tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each      = local.non_rotating_service_accounts
  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = local.service_account_secret_payloads[each.key]

  lifecycle {
    replace_triggered_by = [openai_service_account.this[each.key]]
  }
}

resource "aws_secretsmanager_secret_version" "rotation_bootstrap" {
  for_each       = local.rotating_service_accounts
  secret_id      = aws_secretsmanager_secret.this[each.key].id
  secret_string  = local.service_account_bootstrap_payloads[each.key]
  version_stages = ["TFBOOTSTRAP"]

  # Never restore the bootstrap marker over Lambda-promoted AWSCURRENT.
  lifecycle {
    ignore_changes = [secret_string, version_stages]
  }
}

resource "aws_secretsmanager_secret_version" "rotation_config" {
  for_each       = local.rotating_service_accounts
  secret_id      = aws_secretsmanager_secret_version.rotation_bootstrap[each.key].secret_id
  secret_string  = local.service_account_rotation_configs[each.key]
  version_stages = ["TFCONFIG"]
}

resource "aws_secretsmanager_secret" "admin_key" {
  for_each    = local.admin_keys
  name        = "${local.admin_secret_paths[each.key]}/${local.admin_secret_names[each.key]}"
  description = local.admin_secret_descriptions[each.key]
  tags        = local.all_tags
}

resource "aws_secretsmanager_secret_version" "admin_key" {
  for_each      = local.non_rotating_admin_keys
  secret_id     = aws_secretsmanager_secret.admin_key[each.key].id
  secret_string = local.admin_secret_payloads[each.key]

  lifecycle {
    replace_triggered_by = [openai_admin_api_key.this[each.key]]
  }
}

resource "aws_secretsmanager_secret_version" "admin_rotation_bootstrap" {
  for_each       = local.rotating_admin_keys
  secret_id      = aws_secretsmanager_secret.admin_key[each.key].id
  secret_string  = local.admin_bootstrap_payloads[each.key]
  version_stages = ["TFBOOTSTRAP"]

  lifecycle {
    ignore_changes = [secret_string, version_stages]
  }
}

resource "aws_secretsmanager_secret_version" "admin_rotation_config" {
  for_each       = local.rotating_admin_keys
  secret_id      = aws_secretsmanager_secret_version.admin_rotation_bootstrap[each.key].secret_id
  secret_string  = local.admin_rotation_configs[each.key]
  version_stages = ["TFCONFIG"]
}

data "aws_lambda_function" "rotation" {
  count         = var.settings.rotation_lambda == null ? 0 : startswith(var.settings.rotation_lambda, "arn:") ? 0 : 1
  function_name = var.settings.rotation_lambda
}

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each            = local.rotating_service_accounts
  secret_id           = aws_secretsmanager_secret_version.rotation_config[each.key].secret_id
  rotation_lambda_arn = startswith(var.settings.rotation_lambda, "arn:") ? var.settings.rotation_lambda : data.aws_lambda_function.rotation[0].arn

  rotation_rules {
    automatically_after_days = var.settings.rotation_period_days
  }

  depends_on = [aws_secretsmanager_secret_version.rotation_config]
}

resource "aws_secretsmanager_secret_rotation" "admin_key" {
  for_each            = local.rotating_admin_keys
  secret_id           = aws_secretsmanager_secret_version.admin_rotation_config[each.key].secret_id
  rotation_lambda_arn = startswith(var.settings.rotation_lambda, "arn:") ? var.settings.rotation_lambda : data.aws_lambda_function.rotation[0].arn

  rotation_rules {
    automatically_after_days = var.settings.rotation_period_days
  }

  depends_on = [aws_secretsmanager_secret_version.admin_rotation_config]
}

##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  rotation_uses_legacy_interval = var.settings.rotation_cron_expression == null && var.settings.rotation_period_days == 1000
  rotation_schedule_expression = (
    var.settings.rotation_cron_expression != null ? join(" ", regexall("\\S+", var.settings.rotation_cron_expression)) :
    local.rotation_uses_legacy_interval ? null :
    format("rate(%s %s)", var.settings.rotation_period_days, var.settings.rotation_period_days == 1 ? "day" : "days")
  )
  rotation_window_duration = var.settings.rotation_window_hours == null ? null : "${var.settings.rotation_window_hours}h"

  # Flatten projects → service_accounts into a single map keyed by "<proj_key>/<sa_key>".
  # The OpenAI project ID comes from proj.project_id; the outer map key is a logical name.
  service_accounts = {
    for item in flatten([
      for proj_key, proj in try(var.settings.projects, {}) : [
        for sa_key, sa in try(proj.service_accounts, {}) : {
          project_key        = proj_key
          key                = "${proj_key}/${sa_key}"
          project_id         = proj.project_id
          name_prefix        = try(sa.name_prefix, null)
          name               = try(sa.name, null)
          role               = try(sa.role, null)
          scopes             = try(sa.scopes, null)
          expires_in_seconds = sa.expires_in_seconds
          secret             = try(sa.secret, {})
        }
      ]
    ]) : item.key => item
  }

  rotating_service_accounts = {
    for key, account in local.service_accounts : key => account
    if var.settings.rotation_lambda != null && account.secret.rotation_enabled
  }

  non_rotating_service_accounts = {
    for key, account in local.service_accounts : key => account
    if var.settings.rotation_lambda == null || !account.secret.rotation_enabled
  }

  # An enrolled service account retains Terraform ownership of its identity;
  # Lambda owns every rotating API key, including the first.
  service_account_resources = merge(openai_service_account.this, openai_service_account.rotating)

  # Compute the effective name for each OpenAI service account.
  # If name_prefix is set: name_prefix + "-" + system_name; otherwise use the fixed name.
  sa_names = {
    for k, v in local.service_accounts : k => (
      v.name_prefix != null
      ? "${v.name_prefix}-${local.system_name}"
      : v.name
    )
  }

  # Compute the effective Secrets Manager secret name for each service account.
  # Priority: secret.name_prefix > secret.name > service account name_prefix > service account name.
  secret_names = {
    for k, v in local.service_accounts : k => (
      try(v.secret.name_prefix, null) != null ? "${v.secret.name_prefix}-${local.system_name}" :
      try(v.secret.name, null) != null ? v.secret.name :
      v.name_prefix != null ? "${v.name_prefix}-${local.system_name}" :
      v.name
    )
  }

  # Compute the Secrets Manager path for each service account.
  # Defaults to the module-level secret_store_path derived from org variables.
  secret_paths = {
    for k, v in local.service_accounts : k => (
      try(v.secret.path, null) != null ? v.secret.path : format("%s/%s", local.secret_store_path, v.project_key)
    )
  }

  # Compute the optional description for each service account secret.
  secret_descriptions = {
    for k, v in local.service_accounts : k => try(v.secret.description, null)
  }

  # Admin keys: org-level, not tied to a project.
  admin_keys = try(var.settings.admin_keys, {})

  rotating_admin_keys = {
    for key, api_key in local.admin_keys : key => api_key
    if var.settings.rotation_lambda != null && api_key.secret.rotation_enabled
  }

  non_rotating_admin_keys = {
    for key, api_key in local.admin_keys : key => api_key
    if var.settings.rotation_lambda == null || !api_key.secret.rotation_enabled
  }

  admin_key_names = {
    for k, v in local.admin_keys : k => (
      v.name_prefix != null
      ? "${v.name_prefix}-${local.system_name}"
      : v.name
    )
  }

  admin_secret_names = {
    for k, v in local.admin_keys : k => (
      try(v.secret.name_prefix, null) != null ? "${v.secret.name_prefix}-${local.system_name}" :
      try(v.secret.name, null) != null ? v.secret.name :
      v.name_prefix != null ? "${v.name_prefix}-${local.system_name}" :
      v.name
    )
  }

  admin_secret_paths = {
    for k, v in local.admin_keys : k => (
      try(v.secret.path, null) != null ? trimsuffix(v.secret.path, "/") : format("%s/admin", local.secret_store_path)
    )
  }

  # Compute the optional description for each admin key secret.
  admin_secret_descriptions = {
    for k, v in local.admin_keys : k => try(v.secret.description, null)
  }
}

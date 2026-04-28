##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  # Flatten projects → service_accounts into a single map keyed by "<proj_key>/<sa_key>".
  # The OpenAI project ID comes from proj.project_id; the outer map key is a logical name.
  service_accounts = {
    for item in flatten([
      for proj_key, proj in try(var.settings.projects, {}) : [
        for sa_key, sa in try(proj.service_accounts, {}) : {
          project_key = proj_key
          key         = "${proj_key}/${sa_key}"
          project_id  = proj.project_id
          name_prefix = try(sa.name_prefix, null)
          name        = try(sa.name, null)
          secret      = try(sa.secret, {})
        }
      ]
    ]) : item.key => item
  }

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

  # Determine whether to store plain string or JSON {"api_key":"<value>"} per entry.
  secret_plain = {
    for k, v in local.service_accounts : k => try(v.secret.plain, false)
  }

  # Compute the optional description for each service account secret.
  secret_descriptions = {
    for k, v in local.service_accounts : k => try(v.secret.description, null)
  }

  # Admin keys: org-level, not tied to a project.
  admin_keys = try(var.settings.admin_keys, {})

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
      try(v.secret.path, null) != null ? trimsuffix(trimsuffix(v.secret.path, "/"), "/admin") : local.secret_store_path
    )
  }

  admin_secret_plain = {
    for k, v in local.admin_keys : k => try(v.secret.plain, false)
  }

  # Compute the optional description for each admin key secret.
  admin_secret_descriptions = {
    for k, v in local.admin_keys : k => try(v.secret.description, null)
  }
}

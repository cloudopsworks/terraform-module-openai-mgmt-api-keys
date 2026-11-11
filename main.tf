##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Creates Terraform-owned OpenAI project service accounts for nonrotating keys.
# The resource key is "<project_key>/<sa_key>". Creating a service account automatically
# provisions an API key exposed via api_key_value (sensitive, only available at creation time).
# When scopes are set the provider creates a scoped service-account API key instead of the
# default bootstrap key; scope changes replace the service account.
resource "openai_service_account" "this" {
  for_each       = local.non_rotating_service_accounts
  project_id     = each.value.project_id
  name           = local.sa_names[each.key]
  scopes         = toset(try(each.value.scopes, null))
  role           = try(each.value.role, "member")
  create_api_key = true
}

# Keep the service-account identity in Terraform. Lambda creates the first and
# every subsequent API key; the provider must not issue a bootstrap credential.
resource "openai_service_account" "rotating" {
  for_each       = local.rotating_service_accounts
  project_id     = each.value.project_id
  name           = local.sa_names[each.key]
  role           = try(each.value.role, "member")
  create_api_key = false

  # Retain the prior scope state during an existing-account handoff; changing
  # scopes must update TFCONFIG, not replace the service-account identity.
  lifecycle {
    ignore_changes = [scopes]
  }
}

##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Creates an OpenAI project service account for each entry across all configured projects.
# The resource key is "<project_id>/<sa_key>". Creating a service account automatically
# provisions an API key exposed via api_key_value (sensitive, only available at creation time).
resource "openai_project_service_account" "this" {
  for_each   = local.service_accounts
  project_id = each.value.project_id
  name       = local.sa_names[each.key]
}

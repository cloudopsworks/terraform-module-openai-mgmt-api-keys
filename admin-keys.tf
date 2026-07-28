##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
# Manages org-level OpenAI admin API keys. The unredacted value is sensitive and only
# available at creation time — it is persisted immediately to Secrets Manager.
# Expiry is expressed as a relative duration; at most one of the three fields may be set
# and omitting all of them creates a non-expiring key. Changing expiry replaces the key.

resource "openai_admin_api_key" "this" {
  for_each           = local.admin_keys
  name               = local.admin_key_names[each.key]
  expires_in_seconds = try(each.value.expires_in_seconds, each.value.expires_at - timeadd(timestamp(), "0s"), null)
  expire_in_hours    = try(each.value.expires_in_hours, null)
  expire_in_days     = try(each.value.expires_in_days, null)
}

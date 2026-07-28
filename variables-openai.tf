##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# settings:                             # (Optional) Settings for OpenAI API key management
#   projects:                           # (Optional) Map of OpenAI projects keyed by a logical name
#     my-project:                       # Logical key used to identify the project (not the OpenAI project ID)
#       project_id: "proj_xxx"          # (Required) The OpenAI project ID
#       service_accounts:               # (Optional) Map of service account configurations keyed by logical name
#         <key>:
#           name_prefix: "myapp"        # (Optional) Name prefix; final name = name_prefix + "-" + system_name
#           name: "fixed-name"          # (Optional) Fixed name for the service account (mutually exclusive with name_prefix)
#           role: "member"              # (Optional) Project role for the service account. Values: "member", "owner". Default: "member"
#           scopes: []                  # (Optional) Scopes for the API key created with the service account. Default: [] (unscoped key)
#           secret:                     # (Optional) AWS Secrets Manager configuration for storing the API key
#             name_prefix: "myapp"      # (Optional) Secret name prefix; final name = name_prefix + "-" + system_name
#             name: "fixed-secret"      # (Optional) Fixed secret name (mutually exclusive with secret.name_prefix)
#             path: "/custom/path"      # (Optional) Secret path prefix. Default: /<org_unit>/<env_name>/<env_type>/<project_key>
#             plain: false              # (Optional) Store API key as plain string; default false stores JSON {"api_key":"<value>"}
#             description: "..."        # (Optional) Human-readable description for the Secrets Manager secret
#   admin_keys:                         # (Optional) Map of org-level admin API keys keyed by logical name
#     <key>:
#       name_prefix: "admin"            # (Optional) Name prefix; final name = name_prefix + "-" + system_name
#       name: "fixed-name"              # (Optional) Fixed name for the admin API key (mutually exclusive with name_prefix)
#       expires_in_seconds: 3600        # (Optional) Seconds until expiry. Mutually exclusive with expire_in_hours/expire_in_days
#       expire_in_hours: 24             # (Optional) Hours until expiry. Mutually exclusive with expires_in_seconds/expire_in_days
#       expire_in_days: 90              # (Optional) Days until expiry. Mutually exclusive with expires_in_seconds/expire_in_hours
#       secret:                         # (Optional) AWS Secrets Manager configuration for storing the API key
#         name_prefix: "admin"          # (Optional) Secret name prefix; final name = name_prefix + "-" + system_name
#         name: "fixed-secret"          # (Optional) Fixed secret name (mutually exclusive with secret.name_prefix)
#         path: "/custom/path"          # (Optional) Full admin secret parent path. Default path: /<org_unit>/<env_name>/<env_type>/admin
#         plain: false                  # (Optional) Store API key as plain string; default false stores JSON {"api_key":"<value>"}
#         description: "..."            # (Optional) Human-readable description for the Secrets Manager secret
variable "settings" {
  description = "Settings for OpenAI API key management via service accounts and admin keys"
  type = object({
    projects = optional(map(object({           # (Optional) Map keyed by a logical project name
      project_id = string                      # (Required) The OpenAI project ID (e.g. "proj_xxx")
      service_accounts = optional(map(object({ # (Optional) Map of service accounts keyed by logical name
        name_prefix = optional(string)         # (Optional) Name prefix composed as name_prefix + "-" + system_name
        name        = optional(string)         # (Optional) Fixed name for the service account
        role        = optional(string)         # (Optional) Project role for the service account. Possible values: "member", "owner". Default: "member"
        scopes      = optional(set(string))    # (Optional) Scopes for the API key created alongside the service account. Create-only; changing them replaces the service account. Default: null (unscoped key)
        secret = optional(object({
          name_prefix = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name
          name        = optional(string)      # (Optional) Fixed name for the Secrets Manager secret
          path        = optional(string)      # (Optional) Override the default secret path /<org_unit>/<env_name>/<env_type>/<project_key>
          plain       = optional(bool, false) # (Optional) Store the API key as a plain string instead of JSON {"api_key":"<value>"}. Default: false
          description = optional(string)      # (Optional) Human-readable description for the Secrets Manager secret
        }), {})
      })), {})
    })), {})
    admin_keys = optional(map(object({      # (Optional) Map of org-level admin API keys keyed by logical name
      name_prefix        = optional(string) # (Optional) Name prefix composed as name_prefix + "-" + system_name
      name               = optional(string) # (Optional) Fixed name for the admin API key
      expires_in_seconds = optional(number) # (Optional) Seconds until the admin key expires. Mutually exclusive with expire_in_hours and expire_in_days. Default: null (non-expiring)
      expire_in_hours    = optional(number) # (Optional) Hours until the admin key expires. Mutually exclusive with expires_in_seconds and expire_in_days. Default: null (non-expiring)
      expire_in_days     = optional(number) # (Optional) Days until the admin key expires. Mutually exclusive with expires_in_seconds and expire_in_hours. Default: null (non-expiring)
      secret = optional(object({
        name_prefix = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name
        name        = optional(string)      # (Optional) Fixed name for the Secrets Manager secret
        path        = optional(string)      # (Optional) Override the full admin secret parent path. Default: /<org_unit>/<env_name>/<env_type>/admin
        plain       = optional(bool, false) # (Optional) Store the API key as a plain string instead of JSON {"api_key":"<value>"}. Default: false
        description = optional(string)      # (Optional) Human-readable description for the Secrets Manager secret
      }), {})
    })), {})
  })
  default = {}

  validation {
    condition = alltrue(flatten([
      for proj in values(try(var.settings.projects, {})) : [
        for sa in values(try(proj.service_accounts, {})) :
        sa.role == null || contains(["member", "owner"], coalesce(sa.role, "member"))
      ]
    ]))
    error_message = "Each settings.projects.<key>.service_accounts.<key>.role must be either \"member\" or \"owner\"."
  }

  validation {
    condition = alltrue([
      for key in values(try(var.settings.admin_keys, {})) :
      length([
        for value in [key.expires_in_seconds, key.expire_in_hours, key.expire_in_days] : value
        if value != null
      ]) <= 1
    ])
    error_message = "Each settings.admin_keys.<key> may set at most one of expires_in_seconds, expire_in_hours or expire_in_days."
  }
}

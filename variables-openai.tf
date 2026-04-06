##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# settings:                          # (Optional) Settings for OpenAI API key management
#   projects:                        # (Optional) Map of OpenAI projects keyed by a logical name
#     my-project:                    # Logical key used to identify the project (not the OpenAI project ID)
#       project_id: "proj_xxx"       # (Required) The OpenAI project ID
#       service_accounts:            # (Optional) Map of service account configurations keyed by logical name
#         <key>:
#           name_prefix: "myapp"     # (Optional) Name prefix; final name = name_prefix + "-" + system_name
#           name: "fixed-name"       # (Optional) Fixed name for the service account (mutually exclusive with name_prefix)
#           secret:                  # (Optional) AWS Secrets Manager configuration for storing the API key
#             name_prefix: "myapp"   # (Optional) Secret name prefix; final name = name_prefix + "-" + system_name
#             name: "fixed-secret"   # (Optional) Fixed secret name (mutually exclusive with secret.name_prefix)
#             path: "/custom/path"   # (Optional) Secret path prefix. Default: /<org_unit>/<env_name>/<env_type>
#             plain: false           # (Optional) Store API key as plain string; default false stores JSON {"api_key":"<value>"}
#   admin_keys:                      # (Optional) Map of org-level admin API keys keyed by logical name
#     <key>:
#       name_prefix: "admin"         # (Optional) Name prefix; final name = name_prefix + "-" + system_name
#       name: "fixed-name"           # (Optional) Fixed name for the admin API key (mutually exclusive with name_prefix)
#       scopes: []                   # (Optional) List of permission scopes (e.g. "projects.read", "api_keys.write")
#       expires_at: 1735689600       # (Optional) Unix timestamp for key expiration
#       secret:                      # (Optional) AWS Secrets Manager configuration for storing the API key
#         name_prefix: "admin"       # (Optional) Secret name prefix; final name = name_prefix + "-" + system_name
#         name: "fixed-secret"       # (Optional) Fixed secret name (mutually exclusive with secret.name_prefix)
#         path: "/custom/path"       # (Optional) Secret path prefix. Default: /<org_unit>/<env_name>/<env_type>
#         plain: false               # (Optional) Store API key as plain string; default false stores JSON {"api_key":"<value>"}
variable "settings" {
  description = "Settings for OpenAI API key management via service accounts and admin keys"
  type = object({
    projects = optional(map(object({           # (Optional) Map keyed by a logical project name
      project_id = string                      # (Required) The OpenAI project ID (e.g. "proj_xxx")
      service_accounts = optional(map(object({ # (Optional) Map of service accounts keyed by logical name
        name_prefix = optional(string)         # (Optional) Name prefix composed as name_prefix + "-" + system_name
        name        = optional(string)         # (Optional) Fixed name for the service account
        secret = optional(object({
          name_prefix = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name
          name        = optional(string)      # (Optional) Fixed name for the Secrets Manager secret
          path        = optional(string)      # (Optional) Override the default secret path /<org_unit>/<env_name>/<env_type>
          plain       = optional(bool, false) # (Optional) Store the API key as a plain string instead of JSON {"api_key":"<value>"}. Default: false
        }), {})
      })), {})
    })), {})
    admin_keys = optional(map(object({         # (Optional) Map of org-level admin API keys keyed by logical name
      name_prefix = optional(string)           # (Optional) Name prefix composed as name_prefix + "-" + system_name
      name        = optional(string)           # (Optional) Fixed name for the admin API key
      scopes      = optional(list(string), []) # (Optional) Permission scopes. Possible values: "users.read", "users.write", "projects.read", "projects.write", "api_keys.read", "api_keys.write", "rate_limits.read", "rate_limits.write"
      expires_at  = optional(number)           # (Optional) Unix timestamp for key expiration
      secret = optional(object({
        name_prefix = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name
        name        = optional(string)      # (Optional) Fixed name for the Secrets Manager secret
        path        = optional(string)      # (Optional) Override the default secret path /<org_unit>/<env_name>/<env_type>
        plain       = optional(bool, false) # (Optional) Store the API key as a plain string instead of JSON {"api_key":"<value>"}. Default: false
      }), {})
    })), {})
  })
  default = {}
}

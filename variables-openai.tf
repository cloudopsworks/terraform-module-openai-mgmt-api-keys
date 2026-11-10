##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# settings:                             # (Optional) Settings for OpenAI API key management. Default: {}
#   rotation_lambda: "rotate-openai"    # (Optional) Module-wide rotation Lambda name or ARN. Default: null (rotation disabled)
#   rotation_period_days: 30            # (Optional) Shared rotation interval, whole days from 1 through 1000. Default: 30
#   projects:                           # (Optional) Map of OpenAI projects keyed by a logical name
#     my-project:                       # Logical key used to identify the project (not the OpenAI project ID)
#       project_id: "proj_xxx"          # (Required) The OpenAI project ID
#       service_accounts:               # (Optional) Map of service account configurations keyed by logical name
#         <key>:
#           name_prefix: "myapp"        # (Optional) Name prefix; final name = name_prefix + "-" + system_name
#           name: "fixed-name"          # (Optional) Fixed name for the service account (mutually exclusive with name_prefix)
#           role: "member"              # (Optional) Project role for the service account. Values: "member", "owner". Default: "member"
#           scopes:                     # (Optional) Project-key scopes. Default: null; [] is not "no access". Lambda owns all rotating keys
#             - "api.model.request"     #            With rotation, later changes update TFCONFIG without replacing the account
#           secret:                     # (Optional) AWS Secrets Manager configuration for storing the API key
#             name_prefix: "myapp"      # (Optional) Secret name prefix; final name = name_prefix + "-" + system_name
#             name: "fixed-secret"      # (Optional) Fixed secret name (mutually exclusive with secret.name_prefix)
#             path: "/custom/path"      # (Optional) Secret path prefix. Default: /<org_unit>/<env_name>/<env_type>/<project_key>
#             plain: false              # (Optional, deprecated) Must be false; all credentials use structured JSON
#             description: "..."        # (Optional) Human-readable description for the Secrets Manager secret
#             rotation_enabled: true     # (Optional) Enroll this key when rotation_lambda is set. Default: true; false opts out (not recommended)
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
#         plain: false                  # (Optional, deprecated) Must be false; all credentials use structured JSON
#         description: "..."            # (Optional) Human-readable description for the Secrets Manager secret
#         rotation_enabled: true         # (Optional) Enroll this key when rotation_lambda is set. Default: true; false opts out (not recommended)
variable "settings" {
  description = "Settings for OpenAI API key management via service accounts and admin keys"
  type = object({
    rotation_lambda      = optional(string)     # (Optional) Lambda function name or ARN; null disables rotation
    rotation_period_days = optional(number, 30) # (Optional) Shared whole-day interval from 1 through 1000. Default: 30
    projects = optional(map(object({            # (Optional) Map keyed by a logical project name
      project_id = string                       # (Required) The OpenAI project ID (e.g. "proj_xxx")
      service_accounts = optional(map(object({  # (Optional) Map of service accounts keyed by logical name
        name_prefix = optional(string)          # (Optional) Name prefix composed as name_prefix + "-" + system_name
        name        = optional(string)          # (Optional) Fixed name for the service account
        role        = optional(string)          # (Optional) Project role for the service account. Possible values: "member", "owner". Default: "member"
        scopes      = optional(set(string))     # (Optional) Project-key scopes. Default: null; changes replace the account only without rotation, otherwise update TFCONFIG
        secret = optional(object({
          name_prefix      = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name
          name             = optional(string)      # (Optional) Fixed name for the Secrets Manager secret
          path             = optional(string)      # (Optional) Override the default secret path /<org_unit>/<env_name>/<env_type>/<project_key>
          plain            = optional(bool, false) # (Optional, deprecated) Must be false; credentials are structured JSON
          description      = optional(string)      # (Optional) Human-readable description for the Secrets Manager secret
          rotation_enabled = optional(bool, true)  # (Optional) Enroll in module-wide rotation. Default: true; false opts out (not recommended)
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
        name_prefix      = optional(string)      # (Optional) Secret name prefix composed as name_prefix + "-" + system_name
        name             = optional(string)      # (Optional) Fixed name for the Secrets Manager secret
        path             = optional(string)      # (Optional) Override the full admin secret parent path. Default: /<org_unit>/<env_name>/<env_type>/admin
        plain            = optional(bool, false) # (Optional, deprecated) Must be false; credentials are structured JSON
        description      = optional(string)      # (Optional) Human-readable description for the Secrets Manager secret
        rotation_enabled = optional(bool, true)  # (Optional) Enroll in module-wide rotation. Default: true; false opts out (not recommended)
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
    condition = alltrue(concat(
      flatten([
        for project in values(var.settings.projects) : [
          for account in values(project.service_accounts) : (
            (account.name_prefix == null) != (account.name == null) &&
            (try(trimspace(account.name_prefix), "") != "" || try(trimspace(account.name), "") != "")
          )
        ]
      ]),
      [
        for api_key in values(var.settings.admin_keys) : (
          (api_key.name_prefix == null) != (api_key.name == null) &&
          (try(trimspace(api_key.name_prefix), "") != "" || try(trimspace(api_key.name), "") != "")
        )
      ]
    ))
    error_message = "Every service account and admin key must set exactly one nonempty name or name_prefix."
  }

  validation {
    condition = alltrue(concat(
      flatten([
        for project in values(var.settings.projects) : [
          for account in values(project.service_accounts) : (
            !(account.secret.name_prefix != null && account.secret.name != null) &&
            (account.secret.name_prefix == null || try(trimspace(account.secret.name_prefix), "") != "") &&
            (account.secret.name == null || try(trimspace(account.secret.name), "") != "")
          )
        ]
      ]),
      [
        for api_key in values(var.settings.admin_keys) : (
          !(api_key.secret.name_prefix != null && api_key.secret.name != null) &&
          (api_key.secret.name_prefix == null || try(trimspace(api_key.secret.name_prefix), "") != "") &&
          (api_key.secret.name == null || try(trimspace(api_key.secret.name), "") != "")
        )
      ]
    ))
    error_message = "Each secret may set at most one nonempty secret.name or secret.name_prefix."
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

  validation {
    condition = var.settings.rotation_lambda == null ? true : (
      can(regex("^arn:[^:]+:lambda:[^:]+:[0-9]{12}:function:[^:]+(?::[^:]+)?$", var.settings.rotation_lambda)) ||
      can(regex("^[A-Za-z0-9_-]{1,64}$", var.settings.rotation_lambda))
    )
    error_message = "settings.rotation_lambda must be a Lambda function name (1-64 letters, numbers, underscores or hyphens) or full function ARN."
  }

  validation {
    condition = (
      var.settings.rotation_period_days >= 1 &&
      var.settings.rotation_period_days <= 1000 &&
      var.settings.rotation_period_days == floor(var.settings.rotation_period_days)
    )
    error_message = "settings.rotation_period_days must be a whole number from 1 through 1000."
  }

  validation {
    condition = alltrue(concat(
      flatten([
        for project in values(var.settings.projects) : [
          for account in values(project.service_accounts) : !account.secret.plain
        ]
      ]),
      [for api_key in values(var.settings.admin_keys) : !api_key.secret.plain]
    ))
    error_message = "secret.plain must be false for every service account and admin key; every active credential is structured JSON."
  }

  validation {
    condition = alltrue([
      for api_key in values(var.settings.admin_keys) : alltrue([
        for seconds in [
          api_key.expires_in_seconds,
          api_key.expire_in_hours == null ? null : api_key.expire_in_hours * 3600,
          api_key.expire_in_days == null ? null : api_key.expire_in_days * 86400
        ] : seconds == null ? true : (seconds >= 1 && seconds <= 31536000 && seconds == floor(seconds))
      ])
    ])
    error_message = "Each admin key expiry must resolve to a whole number of seconds from 1 through 31536000 (one year)."
  }
}

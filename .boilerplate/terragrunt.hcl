locals {
  local_vars  = yamldecode(file("./inputs.yaml"))
  spoke_vars  = yamldecode(file(find_in_parent_folders("spoke-inputs.yaml")))
  region_vars = yamldecode(file(find_in_parent_folders("region-inputs.yaml")))
  env_vars    = yamldecode(file(find_in_parent_folders("env-inputs.yaml")))
  global_vars = yamldecode(file(find_in_parent_folders("global-inputs.yaml")))

  local_tags  = jsondecode(file("./local-tags.json"))
  spoke_tags  = jsondecode(file(find_in_parent_folders("spoke-tags.json")))
  region_tags = jsondecode(file(find_in_parent_folders("region-tags.json")))
  env_tags    = jsondecode(file(find_in_parent_folders("env-tags.json")))
  global_tags = jsondecode(file(find_in_parent_folders("global-tags.json")))

  openai_secret_name         = local.global_vars.openai.secrets.name
  openai_secret_region       = local.global_vars.openai.secrets.region
  openai_secret_sts_role_arn = local.global_vars.openai.secrets.sts_role_arn
  openai_secret_sts_endpoint = local.global_vars.openai.secrets.sts_endpoint
  openai_organization_id     = local.global_vars.openai.organization_id
  openai_secret_api_key      = local.global_vars.openai.secrets.secret_key
  openai_admin_key           = run_cmd("--terragrunt-quiet", "${get_parent_terragrunt_dir()}/.cloudopsworks/hooks/get-secret.sh", local.openai_secret_name, local.openai_secret_api_key, local.openai_secret_region, local.openai_secret_sts_role_arn, local.openai_secret_sts_endpoint)

  tags = merge(
    local.global_tags,
    local.env_tags,
    local.region_tags,
    local.spoke_tags,
    local.local_tags
  )
}

include "root" {
  path = find_in_parent_folders("{{ .RootFileName }}")
}

generate "provider-openai" {
  path      = "provider-openai.g.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "openai" {
  organization = "${local.openai_organization_id}"
}
EOF
}

terraform {
  source = "{{ .sourceUrl }}"
  extra_arguments "openai_api_key" {
    commands = ["plan", "apply", "destroy", "import"]
    env_vars = {
      "OPENAI_ADMIN_KEY" = local.openai_admin_key
    }
  }
}

inputs = {
  is_hub     = {{ .is_hub }}
  org        = local.env_vars.org
  spoke_def  = local.spoke_vars.spoke
  {{- range .requiredVariables }}
  {{- if ne .Name "org" }}
  {{ .Name }} = local.local_vars.{{ .Name }}
  {{- end }}
  {{- end }}
  {{- range .optionalVariables }}
  {{- if not (eq .Name "extra_tags" "is_hub" "spoke_def" "org") }}
  {{ .Name }} = try(local.local_vars.{{ .Name }}, {{ .DefaultValue }})
  {{- end }}
  {{- end }}
  extra_tags = local.tags
}
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
}

mock_provider "openai" {}

variables {
  org = {
    organization_name = "example"
    organization_unit = "platform"
    environment_type  = "production"
    environment_name  = "prod"
  }
}

run "initial_rotating_scope" {
  command = apply

  variables {
    settings = {
      rotation_lambda = "arn:aws:lambda:us-east-1:123456789012:function:rotate-openai"
      projects = {
        engineering = {
          project_id = "proj_engineering"
          service_accounts = {
            backend = {
              name   = "backend"
              scopes = ["api.model.request"]
            }
          }
        }
      }
    }
  }

  assert {
    condition     = jsondecode(aws_secretsmanager_secret_version.rotation_config["engineering/backend"].secret_string).scopes == ["api.model.request"]
    error_message = "Initial TFCONFIG must carry the requested key scope."
  }
}

run "scope_change_keeps_service_account" {
  command = apply

  variables {
    extra_tags = {
      expected_service_account_id = run.initial_rotating_scope.service_account_ids["engineering/backend"]
    }
    settings = {
      rotation_lambda = "arn:aws:lambda:us-east-1:123456789012:function:rotate-openai"
      projects = {
        engineering = {
          project_id = "proj_engineering"
          service_accounts = {
            backend = {
              name   = "backend"
              scopes = ["api.file.read"]
            }
          }
        }
      }
    }
  }

  assert {
    condition = (
      openai_service_account.rotating["engineering/backend"].id == var.extra_tags.expected_service_account_id &&
      jsondecode(aws_secretsmanager_secret_version.rotation_config["engineering/backend"].secret_string).scopes == ["api.file.read"]
    )
    error_message = "Changing a rotating key's scopes must update TFCONFIG without replacing its service-account identity."
  }
}

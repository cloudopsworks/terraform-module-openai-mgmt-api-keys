mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-openai"
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

run "rotation_off_keeps_terraform_ownership" {
  command = apply

  variables {
    settings = {
      projects = {
        engineering = {
          project_id = "proj_engineering"
          service_accounts = {
            backend = { name = "backend" }
          }
        }
      }
      admin_keys = {
        operations = { name = "operations" }
      }
    }
  }

  assert {
    condition = (
      length(openai_service_account.this) == 1 &&
      openai_service_account.this["engineering/backend"].create_api_key == true &&
      length(openai_service_account.rotating) == 0 &&
      length(openai_admin_api_key.this) == 1 &&
      length(aws_secretsmanager_secret_version.this) == 1 &&
      length(aws_secretsmanager_secret_version.admin_key) == 1 &&
      length(aws_secretsmanager_secret_version.rotation_bootstrap) == 0 &&
      length(aws_secretsmanager_secret_version.admin_rotation_bootstrap) == 0 &&
      length(aws_secretsmanager_secret_rotation.this) == 0 &&
      length(aws_secretsmanager_secret_rotation.admin_key) == 0 &&
      jsondecode(aws_secretsmanager_secret_version.this["engineering/backend"].secret_string).api_key_id == openai_service_account.this["engineering/backend"].api_key_id &&
      jsondecode(aws_secretsmanager_secret_version.this["engineering/backend"].secret_string).name == openai_service_account.this["engineering/backend"].api_key_name &&
      jsondecode(aws_secretsmanager_secret_version.this["engineering/backend"].secret_string).project_id == "proj_engineering" &&
      jsondecode(aws_secretsmanager_secret_version.admin_key["operations"].secret_string).api_key_id == openai_admin_api_key.this["operations"].id &&
      jsondecode(aws_secretsmanager_secret_version.admin_key["operations"].secret_string).name == "operations"
    )
    error_message = "Without a Lambda, both credential families remain Terraform-owned."
  }
}

run "module_lambda_rotates_both_families" {
  command = plan

  variables {
    settings = {
      rotation_lambda      = "arn:aws:lambda:us-east-1:123456789012:function:rotate-openai"
      rotation_period_days = 45
      projects = {
        engineering = {
          project_id = "proj_engineering"
          service_accounts = {
            backend = { name = "backend" }
          }
        }
      }
      admin_keys = {
        operations = { name = "operations" }
      }
    }
  }

  assert {
    condition = (
      length(openai_service_account.this) == 0 &&
      length(openai_service_account.rotating) == 1 &&
      openai_service_account.rotating["engineering/backend"].create_api_key == false &&
      length(openai_admin_api_key.this) == 0 &&
      length(aws_secretsmanager_secret_version.rotation_bootstrap) == 1 &&
      length(aws_secretsmanager_secret_version.admin_rotation_bootstrap) == 1 &&
      length(aws_secretsmanager_secret_version.rotation_config) == 1 &&
      length(aws_secretsmanager_secret_version.admin_rotation_config) == 1 &&
      length(aws_secretsmanager_secret_rotation.this) == 1 &&
      length(aws_secretsmanager_secret_rotation.admin_key) == 1 &&
      aws_secretsmanager_secret_rotation.this["engineering/backend"].rotation_rules[0].automatically_after_days == 45 &&
      aws_secretsmanager_secret_rotation.admin_key["operations"].rotation_rules[0].automatically_after_days == 45 &&
      length(data.aws_lambda_function.rotation) == 0
    )
    error_message = "A module-wide Lambda must enroll both key families using one interval."
  }
}

run "default_period_and_lambda_name_lookup" {
  command = plan

  variables {
    settings = {
      rotation_lambda = "rotate-openai"
      admin_keys = {
        operations = { name = "operations" }
      }
    }
  }

  assert {
    condition = (
      length(data.aws_lambda_function.rotation) == 1 &&
      aws_secretsmanager_secret_rotation.admin_key["operations"].rotation_rules[0].automatically_after_days == 30 &&
      aws_secretsmanager_secret_rotation.admin_key["operations"].rotation_lambda_arn == data.aws_lambda_function.rotation[0].arn
    )
    error_message = "A Lambda name must resolve through data lookup and use the 30-day default."
  }
}

run "per_key_opt_out_is_terraform_owned" {
  command = plan

  variables {
    settings = {
      rotation_lambda = "arn:aws:lambda:us-east-1:123456789012:function:rotate-openai"
      projects = {
        engineering = {
          project_id = "proj_engineering"
          service_accounts = {
            backend = { name = "backend" }
            reporting = {
              name   = "reporting"
              secret = { rotation_enabled = false }
            }
          }
        }
      }
      admin_keys = {
        operations = { name = "operations" }
        legacy = {
          name   = "legacy"
          secret = { rotation_enabled = false }
        }
      }
    }
  }

  assert {
    condition = (
      length(openai_service_account.this) == 1 &&
      contains(keys(openai_service_account.this), "engineering/reporting") &&
      length(openai_service_account.rotating) == 1 &&
      contains(keys(openai_service_account.rotating), "engineering/backend") &&
      length(openai_admin_api_key.this) == 1 &&
      contains(keys(openai_admin_api_key.this), "legacy") &&
      length(aws_secretsmanager_secret_version.this) == 1 &&
      length(aws_secretsmanager_secret_version.admin_key) == 1 &&
      length(aws_secretsmanager_secret_rotation.this) == 1 &&
      length(aws_secretsmanager_secret_rotation.admin_key) == 1
    )
    error_message = "Per-key opt-out must preserve Terraform-owned credentials and versions."
  }
}

run "structured_payloads_and_rotation_config" {
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
              scopes = ["api.model.request", "api.file.read"]
            }
          }
        }
      }
      admin_keys = {
        operations = {
          name            = "operations"
          expire_in_hours = 24
        }
      }
    }
  }

  assert {
    condition = (
      jsondecode(aws_secretsmanager_secret_version.rotation_bootstrap["engineering/backend"].secret_string).key_type == "project" &&
      jsondecode(aws_secretsmanager_secret_version.rotation_bootstrap["engineering/backend"].secret_string).api_key == null &&
      jsondecode(aws_secretsmanager_secret_version.rotation_bootstrap["engineering/backend"].secret_string).api_key_id == "__CREATE_NEW__" &&
      jsondecode(aws_secretsmanager_secret_version.rotation_bootstrap["engineering/backend"].secret_string).name == "backend" &&
      length(keys(jsondecode(aws_secretsmanager_secret_version.rotation_bootstrap["engineering/backend"].secret_string))) == 6 &&
      jsondecode(aws_secretsmanager_secret_version.rotation_bootstrap["engineering/backend"].secret_string).project_id == "proj_engineering" &&
      jsondecode(aws_secretsmanager_secret_version.rotation_bootstrap["engineering/backend"].secret_string).service_account_id == openai_service_account.rotating["engineering/backend"].id &&
      contains(aws_secretsmanager_secret_version.rotation_bootstrap["engineering/backend"].version_stages, "TFBOOTSTRAP") &&
      jsondecode(aws_secretsmanager_secret_version.admin_rotation_bootstrap["operations"].secret_string).api_key == null &&
      jsondecode(aws_secretsmanager_secret_version.admin_rotation_bootstrap["operations"].secret_string).api_key_id == "__CREATE_NEW__" &&
      length(keys(jsondecode(aws_secretsmanager_secret_version.admin_rotation_bootstrap["operations"].secret_string))) == 2 &&
      contains(aws_secretsmanager_secret_version.admin_rotation_bootstrap["operations"].version_stages, "TFBOOTSTRAP") &&
      jsondecode(aws_secretsmanager_secret_version.rotation_config["engineering/backend"].secret_string).schema_version == 1 &&
      jsondecode(aws_secretsmanager_secret_version.rotation_config["engineering/backend"].secret_string).key_type == "project" &&
      jsondecode(aws_secretsmanager_secret_version.rotation_config["engineering/backend"].secret_string).name == "backend" &&
      jsondecode(aws_secretsmanager_secret_version.rotation_config["engineering/backend"].secret_string).scopes == ["api.file.read", "api.model.request"] &&
      jsondecode(aws_secretsmanager_secret_version.rotation_config["engineering/backend"].secret_string).role == "member" &&
      jsondecode(aws_secretsmanager_secret_version.admin_rotation_config["operations"].secret_string).schema_version == 1 &&
      jsondecode(aws_secretsmanager_secret_version.admin_rotation_config["operations"].secret_string).key_type == "admin" &&
      jsondecode(aws_secretsmanager_secret_version.admin_rotation_config["operations"].secret_string).expires_in_seconds == 86400 &&
      length(output.rotation_secret_arns) == 1 &&
      length(output.rotation_config_version_ids) == 1 &&
      length(output.admin_rotation_secret_arns) == 1 &&
      length(output.admin_rotation_config_version_ids) == 1
    )
    error_message = "Bootstrap versions and TFCONFIG must carry complete project/admin contracts."
  }
}

run "plain_secrets_are_rejected" {
  command = plan

  variables {
    settings = {
      admin_keys = {
        operations = {
          name   = "operations"
          secret = { plain = true }
        }
      }
    }
  }

  expect_failures = [var.settings]
}

run "fractional_rotation_period_is_rejected" {
  command = plan

  variables {
    settings = {
      rotation_period_days = 1.5
    }
  }

  expect_failures = [var.settings]
}

run "invalid_admin_ttl_is_rejected" {
  command = plan

  variables {
    settings = {
      admin_keys = {
        operations = {
          name           = "operations"
          expire_in_days = 366
        }
      }
    }
  }

  expect_failures = [var.settings]
}

run "nonrotating_admin_ttl_reaches_provider" {
  command = plan

  variables {
    settings = {
      admin_keys = {
        operations = {
          name               = "operations"
          expires_in_seconds = 3600
        }
      }
    }
  }

  assert {
    condition     = openai_admin_api_key.this["operations"].expires_in_seconds == 3600
    error_message = "A nonrotating admin key must preserve its configured relative TTL."
  }
}

run "rotating_admin_key_requires_name" {
  command = plan

  variables {
    settings = {
      rotation_lambda = "arn:aws:lambda:us-east-1:123456789012:function:rotate-openai"
      admin_keys = {
        operations = {}
      }
    }
  }

  expect_failures = [var.settings]
}

run "service_account_requires_one_name" {
  command = plan

  variables {
    settings = {
      projects = {
        engineering = {
          project_id = "proj_engineering"
          service_accounts = {
            backend = { name = "backend", name_prefix = "other" }
          }
        }
      }
    }
  }

  expect_failures = [var.settings]
}

run "secret_name_selectors_are_exclusive" {
  command = plan

  variables {
    settings = {
      admin_keys = {
        operations = {
          name = "operations"
          secret = {
            name        = "operations"
            name_prefix = "other"
          }
        }
      }
    }
  }

  expect_failures = [var.settings]
}

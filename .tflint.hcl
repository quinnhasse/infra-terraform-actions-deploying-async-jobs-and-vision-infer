config {
  # Cache downloaded plugins locally.
  plugin_dir = ".tflint.d/plugins"

  call_module_type = "all"
}

plugin "aws" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# ── Rule overrides ────────────────────────────────────────────────────────────

# Warn on deprecated resource types.
rule "terraform_deprecated_index" {
  enabled = true
}

# Enforce consistent naming.
rule "terraform_naming_convention" {
  enabled = true

  variable {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }
}

# Require all variables to have a description.
rule "terraform_documented_variables" {
  enabled = true
}

# Require all outputs to have a description.
rule "terraform_documented_outputs" {
  enabled = true
}

# Disallow legacy count-based meta-arguments where for_each is cleaner.
rule "terraform_count_index_usage" {
  enabled = true
}

# Warn on unused declarations.
rule "terraform_unused_declarations" {
  enabled = true
}

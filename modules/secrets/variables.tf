variable "name" {
  description = "Identifier prefix for all resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (staging, prod)."
  type        = string
}

variable "secrets" {
  description = <<-EOT
    Map of logical name → secret configuration.
    Each value is an object with:
      - description: human-readable description
      - initial_value: JSON string written on first create (rotate immediately after)
  EOT
  type = map(object({
    description   = string
    initial_value = string
  }))
  default = {}
}

variable "task_role_arns" {
  description = "IAM role ARNs that need GetSecretValue on all managed secrets."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

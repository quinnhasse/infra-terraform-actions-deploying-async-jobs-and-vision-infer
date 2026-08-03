output "secret_arns" {
  description = "Map of logical name → Secrets Manager ARN."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.arn }
}

output "secret_names" {
  description = "Map of logical name → Secrets Manager secret name."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.name }
}

output "read_policy_arn" {
  description = "IAM policy ARN granting GetSecretValue on all managed secrets (empty if no secrets)."
  value       = length(aws_iam_policy.read_secrets) > 0 ? aws_iam_policy.read_secrets[0].arn : ""
}

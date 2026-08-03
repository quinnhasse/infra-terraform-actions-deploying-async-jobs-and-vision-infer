output "async_jobs_cluster_name" {
  description = "ECS cluster name for async-jobs."
  value       = module.async_jobs.cluster_name
}

output "async_jobs_log_group" {
  description = "CloudWatch log group for async-jobs."
  value       = module.async_jobs.log_group_name
}

output "vision_infer_cluster_name" {
  description = "ECS cluster name for vision-infer."
  value       = module.vision_infer.cluster_name
}

output "vision_infer_log_group" {
  description = "CloudWatch log group for vision-infer."
  value       = module.vision_infer.log_group_name
}

output "postgres_endpoint" {
  description = "RDS endpoint."
  value       = module.postgres.endpoint
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint."
  value       = module.redis.primary_endpoint
}

output "secret_arns" {
  description = "Secrets Manager ARNs."
  value       = module.secrets.secret_arns
}

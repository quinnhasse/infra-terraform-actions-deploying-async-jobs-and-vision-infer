output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "cluster_id" {
  description = "ECS cluster ID."
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "Latest active task definition ARN."
  value       = aws_ecs_task_definition.this.arn
}

output "task_security_group_id" {
  description = "Security group attached to ECS tasks."
  value       = aws_security_group.task.id
}

output "target_group_arn" {
  description = "ALB target group ARN."
  value       = aws_lb_target_group.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group name."
  value       = aws_cloudwatch_log_group.this.name
}

output "task_role_arn" {
  description = "IAM role ARN used by the ECS task."
  value       = local.task_role_arn
}

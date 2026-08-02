variable "name" {
  description = "Service name (e.g. async-jobs, vision-infer)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (staging, prod)."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC to deploy into."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for ECS tasks."
  type        = list(string)
}

variable "alb_listener_arn" {
  description = "HTTPS listener ARN on the shared ALB."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group of the shared ALB (so tasks allow inbound from it)."
  type        = string
}

variable "container_image" {
  description = "Full container image URI (registry/repo:tag)."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "ECS task CPU units (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 512
}

variable "memory" {
  description = "ECS task memory in MiB."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of running tasks."
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "ALB health check path."
  type        = string
  default     = "/healthz"
}

variable "alb_path_pattern" {
  description = "ALB listener rule path pattern for this service."
  type        = string
  default     = "/*"
}

variable "alb_priority" {
  description = "ALB listener rule priority."
  type        = number
  default     = 100
}

variable "task_role_arn" {
  description = "IAM role ARN for the ECS task (application permissions)."
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Map of environment variable name → value injected into the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of environment variable name → Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

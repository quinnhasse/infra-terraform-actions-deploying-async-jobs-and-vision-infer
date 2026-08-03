variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for staging."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for ECS tasks."
  type        = list(string)
}

variable "data_subnet_ids" {
  description = "Private subnets for RDS and ElastiCache (data tier)."
  type        = list(string)
}

variable "alb_listener_arn" {
  description = "HTTPS ALB listener ARN."
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID."
  type        = string
}

variable "async_jobs_image" {
  description = "Container image for async-jobs."
  type        = string
}

variable "vision_infer_image" {
  description = "Container image for vision-infer."
  type        = string
}

variable "db_password_secret_arn" {
  description = "Secrets Manager ARN containing the Postgres master password."
  type        = string
}

variable "name" {
  description = "Identifier prefix for all resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (staging, prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC to deploy into."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the RDS subnet group (typically private/data tier)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect on port 5432."
  type        = list(string)
  default     = []
}

variable "engine_version" {
  description = "Postgres engine version."
  type        = string
  default     = "16.2"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage in GiB for autoscaling (0 to disable)."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the initial database."
  type        = string
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "postgres"
}

variable "db_password_secret_arn" {
  description = "Secrets Manager ARN containing the master password."
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Days to retain automated backups (0 disables backups)."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set true only in non-prod)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

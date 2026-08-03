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
  description = "Subnets for the ElastiCache subnet group (typically private/data tier)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect on port 6379."
  type        = list(string)
  default     = []
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "num_cache_clusters" {
  description = "Number of cache nodes (1 = no replica, 2+ = one primary + replicas)."
  type        = number
  default     = 1
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_clusters >= 2)."
  type        = bool
  default     = false
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest."
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable in-transit encryption (TLS)."
  type        = bool
  default     = true
}

variable "snapshot_retention_limit" {
  description = "Days to retain daily snapshots (0 to disable)."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

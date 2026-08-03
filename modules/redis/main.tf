locals {
  full_name = "${var.environment}-${var.name}"
  default_tags = merge(
    {
      Service     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ── Security group ────────────────────────────────────────────────────────────

resource "aws_security_group" "redis" {
  name        = "${local.full_name}-redis"
  description = "ElastiCache Redis for ${local.full_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "Redis from ECS tasks"
      from_port       = 6379
      to_port         = 6379
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

# ── Subnet group ──────────────────────────────────────────────────────────────

resource "aws_elasticache_subnet_group" "this" {
  name       = local.full_name
  subnet_ids = var.subnet_ids
  tags       = local.default_tags
}

# ── Parameter group ───────────────────────────────────────────────────────────

resource "aws_elasticache_parameter_group" "this" {
  name   = local.full_name
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = local.default_tags
}

# ── Replication group ─────────────────────────────────────────────────────────

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = substr(local.full_name, 0, 40)
  description          = "Redis for ${local.full_name}"

  node_type            = var.node_type
  engine_version       = var.engine_version
  num_cache_clusters   = var.num_cache_clusters
  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id]
  port                 = 6379

  automatic_failover_enabled = var.num_cache_clusters > 1 ? var.automatic_failover_enabled : false
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  transit_encryption_mode    = var.transit_encryption_enabled ? "required" : null

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = "05:00-06:00"
  maintenance_window       = "sun:06:00-sun:07:00"

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = local.default_tags
}

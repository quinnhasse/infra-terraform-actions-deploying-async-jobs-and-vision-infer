locals {
  env = "prod"
  tags = {
    Environment = local.env
    ManagedBy   = "terraform"
  }
}

# ── Postgres ──────────────────────────────────────────────────────────────────

module "postgres" {
  source = "../../modules/postgres"

  name        = "postgres"
  environment = local.env
  vpc_id      = var.vpc_id
  subnet_ids  = var.data_subnet_ids

  allowed_security_group_ids = [
    module.async_jobs.task_security_group_id,
    module.vision_infer.task_security_group_id,
  ]

  db_name                = "app"
  db_password_secret_arn = var.db_password_secret_arn

  instance_class        = "db.t4g.small"
  allocated_storage     = 50
  max_allocated_storage = 200
  multi_az              = true
  backup_retention_days = 14
  deletion_protection   = true
  skip_final_snapshot   = false

  tags = local.tags
}

# ── Redis ─────────────────────────────────────────────────────────────────────

module "redis" {
  source = "../../modules/redis"

  name        = "redis"
  environment = local.env
  vpc_id      = var.vpc_id
  subnet_ids  = var.data_subnet_ids

  allowed_security_group_ids = [
    module.async_jobs.task_security_group_id,
  ]

  node_type                  = "cache.t4g.small"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  snapshot_retention_limit   = 7

  tags = local.tags
}

# ── Secrets ───────────────────────────────────────────────────────────────────

module "secrets" {
  source = "../../modules/secrets"

  name        = "app"
  environment = local.env

  secrets = {
    db_password = {
      description   = "Postgres master password"
      initial_value = jsonencode({ password = "CHANGEME" })
    }
    openai_api_key = {
      description   = "OpenAI API key for vision-infer"
      initial_value = jsonencode({ api_key = "CHANGEME" })
    }
  }

  task_role_arns = [
    module.async_jobs.task_role_arn,
    module.vision_infer.task_role_arn,
  ]

  tags = local.tags
}

# ── async-jobs ECS service ────────────────────────────────────────────────────

module "async_jobs" {
  source = "../../modules/app"

  name        = "async-jobs"
  environment = local.env
  region      = var.region

  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  alb_listener_arn      = var.alb_listener_arn
  alb_security_group_id = var.alb_security_group_id

  container_image   = var.async_jobs_image
  container_port    = 8080
  cpu               = 512
  memory            = 1024
  desired_count     = var.async_jobs_desired_count
  health_check_path = "/healthz"
  alb_path_pattern  = "/jobs/*"
  alb_priority      = 100

  environment_variables = {
    ENV              = local.env
    REDIS_URL        = "rediss://${module.redis.primary_endpoint}:${module.redis.port}"
    DB_HOST          = module.postgres.address
    DB_PORT          = tostring(module.postgres.port)
    DB_NAME          = module.postgres.db_name
  }

  secrets = {
    DB_PASSWORD = module.secrets.secret_arns["db_password"]
  }

  log_retention_days = 90

  tags = local.tags
}

# ── vision-infer ECS service ──────────────────────────────────────────────────

module "vision_infer" {
  source = "../../modules/app"

  name        = "vision-infer"
  environment = local.env
  region      = var.region

  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  alb_listener_arn      = var.alb_listener_arn
  alb_security_group_id = var.alb_security_group_id

  container_image   = var.vision_infer_image
  container_port    = 8080
  cpu               = 2048
  memory            = 4096
  desired_count     = var.vision_infer_desired_count
  health_check_path = "/healthz"
  alb_path_pattern  = "/infer/*"
  alb_priority      = 110

  environment_variables = {
    ENV     = local.env
    DB_HOST = module.postgres.address
    DB_PORT = tostring(module.postgres.port)
    DB_NAME = module.postgres.db_name
  }

  secrets = {
    OPENAI_API_KEY = module.secrets.secret_arns["openai_api_key"]
    DB_PASSWORD    = module.secrets.secret_arns["db_password"]
  }

  log_retention_days = 90

  tags = local.tags
}

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

# ── CloudWatch log group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.full_name}"
  retention_in_days = var.log_retention_days
  tags              = local.default_tags
}

# ── ECS cluster (one per environment, shared across services) ─────────────────

resource "aws_ecs_cluster" "this" {
  name = local.full_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.default_tags
}

# ── IAM: execution role (ECR pull + CloudWatch write) ────────────────────────

data "aws_iam_policy_document" "exec_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "exec" {
  name               = "${local.full_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.exec_assume.json
  tags               = local.default_tags
}

resource "aws_iam_role_policy_attachment" "exec_managed" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── Task role (application permissions passed in via var) ─────────────────────

data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task" {
  count              = var.task_role_arn == "" ? 1 : 0
  name               = "${local.full_name}-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = local.default_tags
}

locals {
  task_role_arn = var.task_role_arn != "" ? var.task_role_arn : aws_iam_role.task[0].arn
}

# ── Security group for ECS tasks ─────────────────────────────────────────────

resource "aws_security_group" "task" {
  name        = "${local.full_name}-task"
  description = "ECS tasks for ${local.full_name}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
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

# ── Task definition ───────────────────────────────────────────────────────────

locals {
  env_vars = [
    for k, v in var.environment_variables : {
      name  = k
      value = v
    }
  ]

  secret_refs = [
    for k, v in var.secrets : {
      name      = k
      valueFrom = v
    }
  ]
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.full_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = local.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = local.env_vars
      secrets     = local.secret_refs

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.name
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -sf http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = local.default_tags
}

# ── ALB target group ──────────────────────────────────────────────────────────

resource "aws_lb_target_group" "this" {
  name        = substr("${local.full_name}-tg", 0, 32)
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  tags = local.default_tags
}

# ── ALB listener rule ─────────────────────────────────────────────────────────

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = [var.alb_path_pattern]
    }
  }
}

# ── ECS service ───────────────────────────────────────────────────────────────

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  tags = local.default_tags

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

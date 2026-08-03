locals {
  prefix = "${var.environment}/${var.name}"
  default_tags = merge(
    {
      Service     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ── Secrets Manager secrets ───────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name        = "${local.prefix}/${each.key}"
  description = each.value.description

  recovery_window_in_days = 7

  tags = local.default_tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.initial_value

  lifecycle {
    # Don't overwrite values that have been rotated outside Terraform.
    ignore_changes = [secret_string]
  }
}

# ── IAM policy: allow task roles to read all managed secrets ──────────────────

data "aws_iam_policy_document" "read_secrets" {
  statement {
    sid    = "GetSecretValue"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      for k, s in aws_secretsmanager_secret.this : s.arn
    ]
  }
}

resource "aws_iam_policy" "read_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  name        = "${local.prefix}-read-secrets"
  description = "GetSecretValue for ${local.prefix} secrets"
  policy      = data.aws_iam_policy_document.read_secrets.json
  tags        = local.default_tags
}

resource "aws_iam_role_policy_attachment" "read_secrets" {
  for_each = length(var.secrets) > 0 ? toset(var.task_role_arns) : toset([])

  role       = element(split("/", each.value), length(split("/", each.value)) - 1)
  policy_arn = aws_iam_policy.read_secrets[0].arn
}

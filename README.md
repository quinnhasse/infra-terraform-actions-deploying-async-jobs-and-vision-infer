# infra

Terraform modules and GitHub Actions pipelines for `async-jobs` and `vision-infer` on AWS ECS Fargate.

Two environments — staging and prod — with separate S3 state backends, separate tfvars, and a CI pipeline that plans on PR and applies on merge to main.

## Architecture

```
                          ┌─────────────────────────────────────────────────┐
                          │  VPC                                            │
                          │                                                 │
    Internet              │  Public subnets                                 │
    ────────► ALB (HTTPS) │  ──────────────────────────────────────────     │
              │           │                                                 │
              │           │  Private subnets (ECS tasks)                   │
              ├──/jobs/*──► ┌──────────────────────────────┐               │
              │            │  ECS Fargate: async-jobs       │               │
              │            │  cpu: 256 (stg) / 512 (prod)  │               │
              │            │  mem: 512 MiB  / 1 GiB        ├──┐            │
              │            └──────────────────────────────┬─┘  │           │
              │                                           │     │           │
              ├──/infer/*─► ┌──────────────────────────────┐   │           │
                            │  ECS Fargate: vision-infer    │   │           │
                            │  cpu: 1024 (stg) / 2048 (prd)│   │           │
                            │  mem: 2 GiB    / 4 GiB       ├─┐ │           │
                            └──────────────────────────────┘ │ │           │
                          │                                   │ │           │
                          │  Data subnets                     │ │           │
                          │  ──────────────────────────       │ │           │
                          │  ┌────────────────────────┐       │ │           │
                          │  │  RDS Postgres 16       │◄──────┘ │           │
                          │  │  gp3, encrypted        │◄────────┘           │
                          │  └────────────────────────┘                     │
                          │  ┌────────────────────────┐                     │
                          │  │  ElastiCache Redis 7   │◄──── async-jobs     │
                          │  │  TLS, encrypted at rest│                     │
                          │  └────────────────────────┘                     │
                          └─────────────────────────────────────────────────┘

  Secrets Manager ──► ECS task role ──► containers (DB_PASSWORD, OPENAI_API_KEY)
  CloudWatch Logs ◄── /ecs/{env}-{service}
```

### Differences between staging and prod

| Resource              | Staging          | Prod                  |
|-----------------------|------------------|-----------------------|
| RDS instance class    | db.t4g.micro     | db.t4g.small          |
| RDS Multi-AZ          | No               | Yes                   |
| RDS backup retention  | 3 days           | 14 days               |
| RDS deletion protect  | Off              | On                    |
| Redis node type       | cache.t4g.micro  | cache.t4g.small       |
| Redis replicas        | 1 node           | 2 nodes + failover    |
| async-jobs task size  | 256 CPU / 512 MB | 512 CPU / 1024 MB     |
| vision-infer task size| 1024 CPU / 2 GB  | 2048 CPU / 4096 MB    |
| Desired task count    | 1 each           | 2 each                |
| Log retention         | 30 days          | 90 days               |

## Repo layout

```
.
├── modules/
│   ├── app/        ECS Fargate service + ALB target group + task IAM roles
│   ├── postgres/   RDS Postgres instance + subnet group + parameter group
│   ├── redis/      ElastiCache replication group + subnet/parameter groups
│   └── secrets/    Secrets Manager secrets + IAM read policy
├── environments/
│   ├── staging/    S3 backend key: staging/terraform.tfstate
│   └── prod/       S3 backend key: prod/terraform.tfstate
├── policy/
│   ├── tags.rego          OPA: required tags on every resource
│   ├── encryption.rego    OPA: storage encrypted at rest
│   └── public_access.rego OPA: no public RDS or public-IP ECS tasks
└── .github/workflows/
    ├── terraform-pr.yml   fmt → tflint → Checkov → plan (with PR comment)
    ├── terraform-apply.yml apply on push to main (staging first, prod after approval)
    ├── drift-detect.yml   scheduled daily plan; opens GitHub issue on diff
    └── opa-policy.yml     OPA checks run against plan JSON on every PR
```

## Prerequisites

- Terraform >= 1.6.0
- An S3 bucket and DynamoDB table for remote state (names set in `backend.tf`)
- GitHub Actions secrets:
  - `AWS_ROLE_ARN_STAGING` — IAM role ARN the staging jobs assume via OIDC
  - `AWS_ROLE_ARN_PROD` — IAM role ARN the prod jobs assume via OIDC
- Existing VPC with private and data-tier subnets, and a shared ALB with an HTTPS listener
- ECR repositories for `async-jobs` and `vision-infer`

### OIDC trust policy (example)

The IAM roles need a trust relationship that allows the GitHub Actions OIDC provider:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:quinnhasse/infra-terraform-actions-deploying-async-jobs-and-vision-infer:*"
    },
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    }
  }
}
```

## Running locally

```bash
cd environments/staging
terraform init
terraform plan -var-file=terraform.tfvars
```

Replace the placeholder values in `terraform.tfvars` with your actual resource IDs before running.

## CI pipeline

### On pull request

1. `terraform fmt -check -recursive` — fails if any file is unformatted.
2. `tflint --recursive` — lints all modules against the AWS ruleset.
3. Checkov — scans for security misconfigurations (HIGH/CRITICAL).
4. `terraform plan` for staging and prod — output posted as a PR comment.
5. OPA policy checks against the plan JSON (tags, encryption, public access).

### On merge to main

1. Detects which environment directories changed (via `dorny/paths-filter`).
2. Applies staging automatically.
3. Waits for the GitHub environment protection approval on prod, then applies.

### Scheduled (daily at 06:00 UTC)

`terraform plan -detailed-exitcode` runs against both environments. Exit code 2 (changes detected) opens a GitHub issue labelled `drift`.

---

## Runbook

### Deploy a new image

1. Push the new image to ECR. Tag it with the git SHA or a semantic version.
2. Update `async_jobs_image` or `vision_infer_image` in `environments/<env>/terraform.tfvars`.
3. Open a PR. The plan comment shows which task definition will be replaced.
4. Merge. The apply workflow updates the ECS task definition; ECS performs a rolling replacement.
   - The circuit breaker (`rollback = true`) rolls back automatically if the new tasks fail health checks.

### Rollback

**Fast path — ECS task definition rollback:**

```bash
# List recent task definition revisions.
aws ecs list-task-definitions \
  --family-prefix <env>-<service> \
  --sort DESC \
  --region us-east-1

# Force the service back to the previous revision.
aws ecs update-service \
  --cluster <env>-<service> \
  --service <service> \
  --task-definition <env>-<service>:<previous-revision> \
  --region us-east-1
```

ECS drains the current tasks and starts the previous revision. No Terraform apply needed for a task-only rollback. Terraform's `ignore_changes = [task_definition]` prevents the next plan from reverting your manual rollback until you update `terraform.tfvars`.

**Terraform state rollback:**

If the apply itself created bad infrastructure (e.g. a wrong security group rule), revert the offending commit on main and merge. The apply workflow will run a corrective plan and apply.

### Secret rotation

Secrets are stored in AWS Secrets Manager. Terraform writes an initial placeholder value (`CHANGEME`) and then ignores further changes via `lifecycle { ignore_changes = [secret_string] }`.

**Rotate a secret:**

```bash
# Update the secret value directly in Secrets Manager.
aws secretsmanager put-secret-value \
  --secret-id <staging|prod>/app/<secret-name> \
  --secret-string '{"password":"<new-value>"}' \
  --region us-east-1
```

The new value is picked up by ECS tasks on their next restart. To force an immediate rollout:

```bash
aws ecs update-service \
  --cluster <env>-<service> \
  --service <service> \
  --force-new-deployment \
  --region us-east-1
```

No Terraform changes are needed for a rotation — Secrets Manager holds the source of truth for secret values after first provision.

### Adding a new secret

1. Add the secret to the `secrets` map in the relevant `environments/<env>/main.tf` under `module "secrets"`.
2. Reference the new ARN in the `secrets` argument of the appropriate `module "async_jobs"` or `module "vision_infer"` block.
3. Open a PR. The plan creates the Secrets Manager secret and updates the task definition to inject it.
4. After apply, set the real value via `aws secretsmanager put-secret-value`.

### Scaling

Change `desired_count` in `terraform.tfvars` (or add an autoscaling policy to the app module) and open a PR. The plan updates the ECS service; changes take effect immediately on apply.

### State backend bootstrap

The S3 bucket and DynamoDB lock table must exist before `terraform init`. Create them once:

```bash
aws s3api create-bucket \
  --bucket my-infra-tfstate \
  --region us-east-1

aws dynamodb create-table \
  --table-name my-infra-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Enable versioning and encryption on the bucket.
aws s3api put-bucket-versioning \
  --bucket my-infra-tfstate \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket my-infra-tfstate \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

# Prod environment variable values.
# Sensitive values (passwords, API keys) are stored in Secrets Manager — not here.

region = "us-east-1"

# Replace these with your actual VPC/subnet/ALB IDs before running.
vpc_id                 = "vpc-0abc123def456prod"
private_subnet_ids     = ["subnet-0prod1", "subnet-0prod2", "subnet-0prod3"]
data_subnet_ids        = ["subnet-0pdata1", "subnet-0pdata2", "subnet-0pdata3"]
alb_listener_arn       = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/prod-alb/abc/def"
alb_security_group_id  = "sg-0prod-alb"
async_jobs_image       = "123456789012.dkr.ecr.us-east-1.amazonaws.com/async-jobs:stable"
vision_infer_image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/vision-infer:stable"
db_password_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/app/db_password-AbCdEf"

async_jobs_desired_count   = 2
vision_infer_desired_count = 2

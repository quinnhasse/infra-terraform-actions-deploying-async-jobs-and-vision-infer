# Staging environment variable values.
# Sensitive values (passwords, API keys) are stored in Secrets Manager — not here.

region = "us-east-1"

# Replace these with your actual VPC/subnet/ALB IDs before running.
vpc_id                 = "vpc-0abc123def456staging"
private_subnet_ids     = ["subnet-0staging1", "subnet-0staging2"]
data_subnet_ids        = ["subnet-0data1", "subnet-0data2"]
alb_listener_arn       = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/staging-alb/abc/def"
alb_security_group_id  = "sg-0staging-alb"
async_jobs_image       = "123456789012.dkr.ecr.us-east-1.amazonaws.com/async-jobs:latest"
vision_infer_image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/vision-infer:latest"
db_password_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:staging/app/db_password-AbCdEf"

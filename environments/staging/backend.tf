terraform {
  backend "s3" {
    bucket         = "my-infra-tfstate"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-infra-tfstate-lock"
  }
}

# S3 Backend Configuration for Terraform State Management
# This ensures all team members and CI/CD pipelines use the same state

terraform {
  backend "s3" {
    bucket         = "iris-terraform-state-1765105240"
    key            = "iris-api/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

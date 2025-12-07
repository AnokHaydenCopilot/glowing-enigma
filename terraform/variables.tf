# Terraform variables for AWS infrastructure configuration

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "iris-classification-api"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "iris-classification-api"
}

# App Runner Configuration
variable "cpu" {
  description = "CPU units for App Runner (0.25 vCPU = 256, 0.5 vCPU = 512, 1 vCPU = 1024, 2 vCPU = 2048)"
  type        = string
  default     = "1024"  # 1 vCPU
}

variable "memory" {
  description = "Memory for App Runner (in MB: 512, 1024, 2048, 3072, 4096, etc.)"
  type        = string
  default     = "2048"  # 2 GB
}

variable "min_size" {
  description = "Minimum number of App Runner instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of App Runner instances"
  type        = number
  default     = 5
}

variable "max_concurrency" {
  description = "Maximum number of concurrent requests per instance"
  type        = number
  default     = 100
}

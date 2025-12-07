# Terraform configuration for Iris Classification API deployment on AWS
# This sets up ECR for container registry and App Runner for serverless container hosting

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# ECR Repository to store Docker images
resource "aws_ecr_repository" "iris_api" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  # Enable image scanning for security
  image_scanning_configuration {
    scan_on_push = true
  }

  # Lifecycle policy to clean up old images
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "Iris Classification API"
    Environment = var.environment
    Project     = "Kursova"
  }
}

# ECR Lifecycle Policy to manage image retention
resource "aws_ecr_lifecycle_policy" "iris_api_policy" {
  repository = aws_ecr_repository.iris_api.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# IAM Role for App Runner
resource "aws_iam_role" "apprunner_service_role" {
  name = "${var.app_name}-apprunner-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-apprunner-service-role"
    Environment = var.environment
  }
}

# Attach policy to allow App Runner to access ECR
resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# IAM Role for App Runner instance (runtime)
resource "aws_iam_role" "apprunner_instance_role" {
  name = "${var.app_name}-apprunner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "tasks.apprunner.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-apprunner-instance-role"
    Environment = var.environment
  }
}

# Auto Scaling Configuration for App Runner
resource "aws_apprunner_auto_scaling_configuration_version" "iris_api" {
  auto_scaling_configuration_name = "iris-api-autoscaling"

  max_concurrency = var.max_concurrency
  max_size        = var.max_size
  min_size        = var.min_size

  tags = {
    Name        = "iris-api-autoscaling"
    Environment = var.environment
  }
}

# App Runner Service
resource "aws_apprunner_service" "iris_api" {
  service_name = var.app_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_service_role.arn
    }

    image_repository {
      image_configuration {
        port = "8000"
        
        runtime_environment_variables = {
          ENVIRONMENT = var.environment
        }
      }

      image_identifier      = "${aws_ecr_repository.iris_api.repository_url}:latest"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.iris_api.arn

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 3
  }

  tags = {
    Name        = var.app_name
    Environment = var.environment
    Project     = "Kursova"
  }
}

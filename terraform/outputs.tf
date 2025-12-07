# Terraform outputs - Important information after deployment

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.iris_api.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.iris_api.arn
}

output "apprunner_service_url" {
  description = "URL of the App Runner service (API endpoint)"
  value       = "https://${aws_apprunner_service.iris_api.service_url}"
}

output "apprunner_service_id" {
  description = "ID of the App Runner service"
  value       = aws_apprunner_service.iris_api.service_id
}

output "apprunner_service_arn" {
  description = "ARN of the App Runner service"
  value       = aws_apprunner_service.iris_api.arn
}

output "apprunner_service_status" {
  description = "Status of the App Runner service"
  value       = aws_apprunner_service.iris_api.status
}

output "api_endpoint_predict" {
  description = "Full URL for the prediction endpoint"
  value       = "https://${aws_apprunner_service.iris_api.service_url}/predict"
}

output "api_endpoint_docs" {
  description = "Full URL for the API documentation (Swagger UI)"
  value       = "https://${aws_apprunner_service.iris_api.service_url}/docs"
}

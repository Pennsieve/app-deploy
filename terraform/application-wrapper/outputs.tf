output "app_ecr_repository" {
  description = "App ECR repository"

  value = aws_ecr_repository.app.repository_url
}

output "app_name" {
  description = "App Name"

  value = var.app_name
}

output "app_id" {
  description = "App Identifier"

  value = aws_ecs_task_definition.application.family
}

output "app_git_url" {
  description = "App Git Repository"

  value = var.app_git_url
}

output "app_region" {
  description = "App Region"

  value = var.region
}
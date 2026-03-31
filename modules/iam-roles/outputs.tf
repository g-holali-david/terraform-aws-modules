output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = var.create_ecs_task_role ? aws_iam_role.ecs_task[0].arn : ""
}

output "cicd_role_arn" {
  description = "CI/CD role ARN"
  value       = var.create_cicd_role ? aws_iam_role.cicd[0].arn : ""
}

output "admin_role_arn" {
  description = "Admin role ARN"
  value       = var.create_admin_role ? aws_iam_role.admin[0].arn : ""
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = var.create_cicd_role ? aws_iam_openid_connect_provider.github[0].arn : ""
}

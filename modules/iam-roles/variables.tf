variable "name" {
  description = "Name prefix for all roles"
  type        = string
}

variable "create_ecs_task_role" {
  description = "Create ECS task role"
  type        = bool
  default     = true
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs the ECS task role can access"
  type        = list(string)
  default     = []
}

variable "sqs_queue_arns" {
  description = "SQS queue ARNs the ECS task role can access"
  type        = list(string)
  default     = []
}

variable "create_cicd_role" {
  description = "Create CI/CD role with GitHub OIDC"
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub organization/user for OIDC trust"
  type        = string
  default     = "g-holali-david"
}

variable "create_admin_role" {
  description = "Create admin break-glass role"
  type        = bool
  default     = false
}

variable "admin_principal_arns" {
  description = "IAM principal ARNs allowed to assume the admin role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

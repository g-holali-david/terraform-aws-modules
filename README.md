# Terraform AWS Modules

[![CI](https://github.com/g-holali-david/terraform-aws-modules/actions/workflows/ci.yml/badge.svg)](https://github.com/g-holali-david/terraform-aws-modules/actions/workflows/ci.yml)

Production-ready, reusable Terraform modules for AWS infrastructure.

## Modules

| Module | Description |
|--------|-------------|
| **[vpc](modules/vpc/)** | VPC + public/private subnets + NAT Gateway + flow logs |
| **[ecs-fargate](modules/ecs-fargate/)** | ECS Fargate service + ALB + auto-scaling + logging |
| **[rds-postgres](modules/rds-postgres/)** | RDS PostgreSQL + subnet group + security group + backups |
| **[s3-cloudfront](modules/s3-cloudfront/)** | S3 bucket + CloudFront distribution + OAC |
| **[iam-roles](modules/iam-roles/)** | IAM roles (ECS task, CI/CD with GitHub OIDC, admin) |

## Quick Start

```hcl
module "vpc" {
  source = "github.com/g-holali-david/terraform-aws-modules//modules/vpc?ref=v1.0.0"

  name               = "myapp"
  vpc_cidr           = "10.0.0.0/16"
  az_count           = 3
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Architecture (Complete Example)

```
┌─────────────────────────────────────────────────────────┐
│                        VPC                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Public Sub-a │  │ Public Sub-b │  │ Public Sub-c │  │
│  │  (ALB, NAT)  │  │  (ALB, NAT)  │  │  (ALB, NAT)  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │           │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐  │
│  │Private Sub-a │  │Private Sub-b │  │Private Sub-c │  │
│  │ (ECS, RDS)   │  │ (ECS, RDS)   │  │ (ECS, RDS)   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
         │                                    │
   ┌─────▼─────┐    ┌──────────┐    ┌───────▼───────┐
   │    ALB     │    │CloudFront│    │     RDS       │
   │(ECS Farg.)│    │  + S3    │    │  PostgreSQL   │
   └───────────┘    └──────────┘    └───────────────┘
```

## Examples

- **[vpc-simple](examples/vpc-simple/)** — VPC with 2 AZs and single NAT
- **[complete](examples/complete/)** — Full stack: VPC + ECS + RDS + S3/CloudFront + IAM

## Module Design Principles

- **Least privilege**: IAM policies scoped to minimum required permissions
- **Encryption by default**: S3 SSE, RDS storage encryption
- **High availability**: Multi-AZ support, auto-scaling, PDB-ready
- **Cost conscious**: Single NAT option, right-sized defaults
- **Security hardened**: Non-root containers, SG least-access, flow logs

## CI Pipeline

Each push runs:
1. `terraform fmt` — formatting check
2. `terraform validate` — syntax validation per module
3. `tflint` — linting rules
4. `checkov` — security scan
5. `terraform-docs` — documentation check

## Testing

Integration tests use [Terratest](https://terratest.gruntwork.io/):

```bash
cd tests
go test -v -timeout 30m
```

> Tests deploy real AWS resources. Use a sandbox account.

## Versioning

Modules are versioned via git tags. Reference a specific version:

```hcl
source = "github.com/g-holali-david/terraform-aws-modules//modules/vpc?ref=v1.0.0"
```

## License

MIT

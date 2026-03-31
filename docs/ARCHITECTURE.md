# Architecture — Terraform AWS Modules

## Vue d'ensemble

Collection de 5 modules Terraform réutilisables pour déployer une infrastructure AWS production-ready. Chaque module est indépendant mais conçu pour s'assembler.

## Diagramme d'architecture complet

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└───────────────┬──────────────────────┬──────────────────────┘
                │                      │
         ┌──────▼──────┐        ┌──────▼──────┐
         │ CloudFront  │        │     ALB     │
         │ (CDN/Static)│        │ (API/Apps)  │
         └──────┬──────┘        └──────┬──────┘
                │                      │
┌───────────────┼──────────────────────┼──────────────────────┐
│               │    VPC Module        │                      │
│  ┌────────────▼────────────┬─────────▼──────────────┐       │
│  │     Public Subnets      │    (NAT Gateways)      │       │
│  └─────────────────────────┴────────────────────────┘       │
│                          │                                   │
│  ┌───────────────────────▼──────────────────────────┐       │
│  │              Private Subnets                      │       │
│  │                                                   │       │
│  │  ┌──────────────┐     ┌──────────────────────┐   │       │
│  │  │  ECS Fargate │     │   RDS PostgreSQL     │   │       │
│  │  │  (2-10 tasks)│────▶│   (encrypted, logs)  │   │       │
│  │  └──────────────┘     └──────────────────────┘   │       │
│  └──────────────────────────────────────────────────┘       │
│                                                              │
│  [VPC Flow Logs → CloudWatch]                                │
└──────────────────────────────────────────────────────────────┘

┌──────────────────┐     ┌─────────────────┐
│   S3 Bucket      │     │   IAM Roles     │
│   (via OAC)      │     │ - ECS task      │
│   ← CloudFront   │     │ - CI/CD (OIDC)  │
└──────────────────┘     │ - Admin (MFA)   │
                         └─────────────────┘
```

## Modules et leurs relations

```
                    ┌──────────┐
                    │   VPC    │
                    └────┬─────┘
                         │ vpc_id, subnet_ids
              ┌──────────┼──────────┐
              │          │          │
        ┌─────▼────┐ ┌──▼───────┐ ┌▼──────────┐
        │ECS Fargate│ │   RDS   │ │S3+CloudFr. │
        └─────┬────┘ └──────────┘ └────────────┘
              │ security_group_id         │ bucket_arn
              └──────────┐                │
                    ┌────▼────────────────▼──┐
                    │      IAM Roles         │
                    └────────────────────────┘
```

### Dépendances entre modules

| Module | Dépend de | Fournit à |
|--------|-----------|-----------|
| **VPC** | — | Tous les autres (vpc_id, subnet_ids) |
| **ECS Fargate** | VPC | IAM (security_group_id), RDS (allowed SG) |
| **RDS** | VPC, ECS (SG) | ECS (endpoint, port) |
| **S3+CloudFront** | — | IAM (bucket_arn) |
| **IAM** | ECS (SG), S3 (ARN) | ECS (task_role), CI/CD |

## Principes de design

### 1. Sécurité par défaut
- Encryption partout (S3 SSE, RDS storage)
- Pas d'accès public par défaut
- Security groups least-access
- IAM least privilege
- VPC Flow Logs activés
- MFA requis pour les rôles admin

### 2. Haute disponibilité
- Multi-AZ (VPC, RDS, ECS)
- Auto-scaling ECS (CPU-based)
- NAT Gateway multi-AZ optionnel
- Circuit breaker sur les déploiements ECS

### 3. Observabilité
- CloudWatch Logs (ECS, VPC Flow Logs)
- Container Insights (ECS)
- RDS Performance Insights
- Logging PostgreSQL (connexions, DDL)

### 4. Maîtrise des coûts
- `single_nat_gateway` pour les environnements non-prod
- `PriceClass_100` par défaut pour CloudFront
- `db.t3.micro` par défaut pour RDS
- Autoscaling pour ajuster la capacité

## CI Pipeline

```
Push/PR
  │
  ├── terraform fmt -check -recursive     (formatting)
  ├── terraform validate (per module)      (syntax)
  ├── tflint (per module)                  (linting)
  ├── checkov (all modules)                (security)
  └── terraform-docs --output-check        (documentation)
```

## Convention de nommage

Toutes les ressources sont préfixées par la variable `name` :

```
{name}-vpc
{name}-public-{az}
{name}-private-{az}
{name}-nat-{index}
{name}-ecs-sg
{name}-alb-sg
{name}-rds-sg
{name}-ecs-task (IAM role)
{name}-cicd (IAM role)
```

## Versioning

Les modules sont versionnés via git tags. Référencez une version spécifique :

```hcl
source = "github.com/g-holali-david/terraform-aws-modules//modules/vpc?ref=v1.0.0"
```

## Estimation de coût (stack complète, eu-west-1)

| Composant | Dev (~) | Production (~) |
|-----------|---------|----------------|
| NAT Gateway | $32/mois | $96/mois (3x) |
| ECS Fargate (2 tasks 0.25vCPU) | $18/mois | $18/mois |
| RDS db.t3.micro | $15/mois | $30/mois (multi-AZ) |
| ALB | $22/mois | $22/mois |
| CloudFront | $0-5/mois | Variable |
| **Total** | **~$87/mois** | **~$166/mois** |

> Hors transfert de données et stockage S3. Utilisez `single_nat_gateway = true` en dev.

# Module IAM Roles

Crée des rôles IAM avec le principe du moindre privilège : rôle ECS task, rôle CI/CD (GitHub OIDC), et rôle admin break-glass.

## Usage

```hcl
module "iam" {
  source = "github.com/g-holali-david/terraform-aws-modules//modules/iam-roles?ref=v1.0.0"

  name = "myapp"

  # Rôle ECS task — accès S3 et SQS
  create_ecs_task_role = true
  s3_bucket_arns       = ["arn:aws:s3:::myapp-data", "arn:aws:s3:::myapp-data/*"]
  sqs_queue_arns       = ["arn:aws:sqs:eu-west-1:123456:myapp-queue"]

  # Rôle CI/CD — GitHub Actions OIDC
  create_cicd_role = true
  github_org       = "g-holali-david"

  # Rôle admin — break-glass avec MFA obligatoire
  create_admin_role    = true
  admin_principal_arns = ["arn:aws:iam::123456:user/admin"]

  tags = { Environment = "production" }
}
```

## Rôles créés

### 1. ECS Task Role (`create_ecs_task_role`)

Rôle assumé par les containers ECS. Permissions :
- **S3** : GetObject, PutObject, ListBucket sur les buckets spécifiés
- **SQS** : SendMessage, ReceiveMessage, DeleteMessage sur les queues spécifiées

Trust policy : `ecs-tasks.amazonaws.com`

### 2. CI/CD Role (`create_cicd_role`)

Rôle pour GitHub Actions via **OIDC federation** (pas de secrets statiques).

Permissions :
- **ECR** : push/pull d'images
- **ECS** : update service, register task definition
- **IAM** : PassRole (limité au préfixe du projet)

Trust policy : GitHub OIDC provider, limité à l'organisation spécifiée.

```yaml
# Utilisation dans GitHub Actions
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ module.iam.cicd_role_arn }}
    aws-region: eu-west-1
```

### 3. Admin Role (`create_admin_role`)

Rôle break-glass avec `AdministratorAccess`. Protections :
- **MFA obligatoire** pour assumer le rôle
- **Session limitée** à 1 heure
- Uniquement assumable par les principaux IAM listés

## Variables

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name` | `string` | — | Préfixe pour les noms de rôles |
| `create_ecs_task_role` | `bool` | `true` | Créer le rôle ECS task |
| `s3_bucket_arns` | `list(string)` | `[]` | ARNs S3 accessibles |
| `sqs_queue_arns` | `list(string)` | `[]` | ARNs SQS accessibles |
| `create_cicd_role` | `bool` | `true` | Créer le rôle CI/CD |
| `github_org` | `string` | `g-holali-david` | Org GitHub pour OIDC |
| `create_admin_role` | `bool` | `false` | Créer le rôle admin |
| `admin_principal_arns` | `list(string)` | `[]` | ARNs autorisés à assumer admin |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Nom | Description |
|-----|-------------|
| `ecs_task_role_arn` | ARN du rôle ECS task |
| `cicd_role_arn` | ARN du rôle CI/CD |
| `admin_role_arn` | ARN du rôle admin |
| `github_oidc_provider_arn` | ARN du provider OIDC GitHub |

## Sécurité

- **Least privilege** : chaque rôle n'a que les permissions nécessaires
- **OIDC** : pas de secrets AWS dans GitHub, authentification fédérée
- **MFA** : obligatoire pour le rôle admin
- **Session courte** : max 1h pour le rôle admin
- **Scope limité** : le CI/CD ne peut faire PassRole que sur les rôles du projet

# Module ECS Fargate

Déploie un service ECS Fargate avec ALB, auto-scaling, logging CloudWatch, et circuit breaker.

## Usage

```hcl
module "ecs" {
  source = "github.com/g-holali-david/terraform-aws-modules//modules/ecs-fargate?ref=v1.0.0"

  name               = "my-api"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  container_image    = "ghcr.io/g-holali-david/my-api:v1.0.0"
  container_port     = 8080
  task_cpu           = 256
  task_memory        = 512
  desired_count      = 2

  enable_alb         = true
  health_check_path  = "/health"

  environment_variables = {
    DB_HOST = "db.internal"
    DB_PORT = "5432"
  }

  enable_autoscaling = true
  min_capacity       = 2
  max_capacity       = 10
  cpu_scaling_target = 75

  tags = { Environment = "production" }
}
```

## Architecture

```
                    ┌──────────┐
        Internet ──▶│   ALB    │ (public subnets)
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
         ┌────▼───┐ ┌───▼────┐ ┌──▼─────┐
         │ Task 1 │ │ Task 2 │ │ Task N │  (private subnets)
         │Fargate │ │Fargate │ │Fargate │
         └────────┘ └────────┘ └────────┘
              │          │          │
              └──────────┼──────────┘
                         │
                  ┌──────▼──────┐
                  │ CloudWatch  │
                  │   Logs      │
                  └─────────────┘
```

## Ressources créées

| Ressource | Quantité | Condition |
|-----------|----------|-----------|
| `aws_ecs_cluster` | 1 | Toujours |
| `aws_ecs_task_definition` | 1 | Toujours |
| `aws_ecs_service` | 1 | Toujours |
| `aws_security_group` (service) | 1 | Toujours |
| `aws_lb` (ALB) | 1 | `enable_alb = true` |
| `aws_lb_target_group` | 1 | `enable_alb = true` |
| `aws_lb_listener` (HTTP) | 1 | `enable_alb = true` |
| `aws_security_group` (ALB) | 1 | `enable_alb = true` |
| `aws_appautoscaling_target` | 1 | `enable_autoscaling = true` |
| `aws_appautoscaling_policy` | 1 | `enable_autoscaling = true` |
| `aws_iam_role` (execution) | 1 | Toujours |
| `aws_iam_role` (task) | 1 | Toujours |
| `aws_cloudwatch_log_group` | 1 | Toujours |

## Variables

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name` | `string` | — | Nom du service ECS |
| `vpc_id` | `string` | — | ID du VPC |
| `vpc_cidr` | `string` | — | CIDR du VPC |
| `public_subnet_ids` | `list(string)` | — | Subnets publics (pour ALB) |
| `private_subnet_ids` | `list(string)` | — | Subnets privés (pour tasks) |
| `container_image` | `string` | — | Image Docker |
| `container_port` | `number` | `8080` | Port du conteneur |
| `task_cpu` | `number` | `256` | CPU units (256/512/1024/2048/4096) |
| `task_memory` | `number` | `512` | Mémoire en MiB |
| `desired_count` | `number` | `2` | Nombre de tasks |
| `enable_alb` | `bool` | `true` | Créer un ALB |
| `health_check_path` | `string` | `/health` | Path du health check |
| `health_check_command` | `string` | `""` | Commande health check container |
| `environment_variables` | `map(string)` | `{}` | Variables d'environnement |
| `enable_autoscaling` | `bool` | `true` | Activer l'autoscaling |
| `min_capacity` | `number` | `2` | Min tasks |
| `max_capacity` | `number` | `10` | Max tasks |
| `cpu_scaling_target` | `number` | `75` | Cible CPU (%) |
| `enable_container_insights` | `bool` | `true` | CloudWatch Container Insights |
| `log_retention_days` | `number` | `30` | Rétention logs CloudWatch |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Nom | Description |
|-----|-------------|
| `cluster_id` | ID du cluster ECS |
| `cluster_name` | Nom du cluster |
| `service_name` | Nom du service |
| `task_definition_arn` | ARN de la task definition |
| `alb_dns_name` | DNS de l'ALB |
| `alb_arn` | ARN de l'ALB |
| `task_role_arn` | ARN du rôle IAM task (pour ajouter des policies) |
| `execution_role_arn` | ARN du rôle IAM execution |
| `service_security_group_id` | ID du security group du service |

## Fonctionnalités de sécurité

- **Deployment circuit breaker** : rollback automatique si le déploiement échoue
- **Security groups** : le service n'accepte le trafic que depuis l'ALB
- **IAM least privilege** : rôles execution et task séparés
- **CloudWatch Logs** : tous les logs conteneurs centralisés
- **Container Insights** : métriques avancées (CPU, mémoire, réseau par task)

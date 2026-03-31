# Module RDS PostgreSQL

Déploie une instance RDS PostgreSQL avec encryption, backups automatiques, et logging.

## Usage

```hcl
module "rds" {
  source = "github.com/g-holali-david/terraform-aws-modules//modules/rds-postgres?ref=v1.0.0"

  name                       = "myapp-db"
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.ecs.service_security_group_id]

  database_name   = "myapp"
  master_username = "postgres"
  master_password = var.db_password

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  multi_az              = true

  backup_retention_days = 7
  deletion_protection   = true

  tags = { Environment = "production" }
}
```

## Ressources créées

| Ressource | Description |
|-----------|-------------|
| `aws_db_instance` | Instance RDS PostgreSQL |
| `aws_db_subnet_group` | Groupe de subnets privés |
| `aws_db_parameter_group` | Paramètres PostgreSQL (logging activé) |
| `aws_security_group` | SG avec accès limité aux SG autorisés |

## Variables

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name` | `string` | — | Identifiant de l'instance RDS |
| `vpc_id` | `string` | — | ID du VPC |
| `private_subnet_ids` | `list(string)` | — | Subnets privés |
| `allowed_security_group_ids` | `list(string)` | — | SG autorisés à se connecter |
| `engine_version` | `string` | `16.4` | Version PostgreSQL |
| `engine_version_major` | `string` | `16` | Version majeure (param group) |
| `instance_class` | `string` | `db.t3.micro` | Classe d'instance |
| `allocated_storage` | `number` | `20` | Stockage initial (GB) |
| `max_allocated_storage` | `number` | `100` | Stockage max autoscaling (GB) |
| `database_name` | `string` | — | Nom de la base |
| `master_username` | `string` | `postgres` | Utilisateur master |
| `master_password` | `string` | — | Mot de passe (sensitive) |
| `multi_az` | `bool` | `false` | Déploiement Multi-AZ |
| `backup_retention_days` | `number` | `7` | Rétention des backups (jours) |
| `deletion_protection` | `bool` | `true` | Protection contre suppression |
| `skip_final_snapshot` | `bool` | `false` | Skip du snapshot final |
| `enable_performance_insights` | `bool` | `true` | Performance Insights |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Nom | Description |
|-----|-------------|
| `endpoint` | Endpoint complet (host:port) |
| `address` | Hostname RDS |
| `port` | Port (5432) |
| `database_name` | Nom de la base |
| `instance_id` | ID de l'instance |
| `security_group_id` | ID du security group |

## Sécurité

- **Encryption at rest** : stockage chiffré par défaut (gp3)
- **Réseau** : accessible uniquement depuis les SG listés (pas d'IP publique)
- **Logging** : connexions, déconnexions, et DDL loggés via parameter group
- **Backups** : fenêtre de backup 03:00-04:00 UTC, maintenance dimanche 04:00-05:00
- **Protection** : deletion protection activée par défaut

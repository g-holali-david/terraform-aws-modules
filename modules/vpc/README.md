# Module VPC

Crée un VPC AWS complet avec subnets publics/privés, NAT Gateway, et VPC Flow Logs.

## Usage

```hcl
module "vpc" {
  source = "github.com/g-holali-david/terraform-aws-modules//modules/vpc?ref=v1.0.0"

  name               = "myapp"
  vpc_cidr           = "10.0.0.0/16"
  az_count           = 3
  enable_nat_gateway = true
  single_nat_gateway = false  # true pour économiser (1 NAT au lieu de 3)
  enable_flow_logs   = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Architecture

```
┌──────────────────── VPC (10.0.0.0/16) ────────────────────┐
│                                                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────┐ │
│  │ Public Subnet a │  │ Public Subnet b │  │ Public c   │ │
│  │  10.0.0.0/24    │  │  10.0.1.0/24    │  │ 10.0.2.0/24│ │
│  │  [NAT GW] [IGW] │  │  [NAT GW]       │  │ [NAT GW]  │ │
│  └────────┬────────┘  └────────┬────────┘  └──────┬─────┘ │
│           │                    │                   │       │
│  ┌────────▼────────┐  ┌───────▼─────────┐  ┌──────▼─────┐ │
│  │ Private Subnet a│  │ Private Subnet b│  │ Private c  │ │
│  │  10.0.3.0/24    │  │  10.0.4.0/24    │  │ 10.0.5.0/24│ │
│  └─────────────────┘  └─────────────────┘  └────────────┘ │
│                                                            │
│  [VPC Flow Logs → CloudWatch]                              │
└────────────────────────────────────────────────────────────┘
```

## Ressources créées

| Ressource | Quantité | Condition |
|-----------|----------|-----------|
| `aws_vpc` | 1 | Toujours |
| `aws_internet_gateway` | 1 | Toujours |
| `aws_subnet` (public) | `az_count` | Toujours |
| `aws_subnet` (private) | `az_count` | Toujours |
| `aws_eip` | 1 ou `az_count` | `enable_nat_gateway = true` |
| `aws_nat_gateway` | 1 ou `az_count` | `enable_nat_gateway = true` |
| `aws_route_table` (public) | 1 | Toujours |
| `aws_route_table` (private) | 1 ou `az_count` | Toujours |
| `aws_flow_log` | 1 | `enable_flow_logs = true` |
| `aws_cloudwatch_log_group` | 1 | `enable_flow_logs = true` |
| `aws_iam_role` (flow log) | 1 | `enable_flow_logs = true` |

## Variables

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `name` | `string` | — (requis) | Préfixe pour toutes les ressources |
| `vpc_cidr` | `string` | `10.0.0.0/16` | Bloc CIDR du VPC |
| `az_count` | `number` | `3` | Nombre de zones de disponibilité |
| `enable_nat_gateway` | `bool` | `true` | Activer le NAT Gateway |
| `single_nat_gateway` | `bool` | `false` | Un seul NAT (économique) |
| `enable_flow_logs` | `bool` | `true` | Activer les VPC Flow Logs |
| `tags` | `map(string)` | `{}` | Tags appliqués à toutes les ressources |

## Outputs

| Nom | Description |
|-----|-------------|
| `vpc_id` | ID du VPC |
| `vpc_cidr` | Bloc CIDR du VPC |
| `public_subnet_ids` | Liste des IDs des subnets publics |
| `private_subnet_ids` | Liste des IDs des subnets privés |
| `public_subnet_cidrs` | Liste des CIDRs des subnets publics |
| `private_subnet_cidrs` | Liste des CIDRs des subnets privés |
| `nat_gateway_ips` | Liste des IPs publiques des NAT Gateways |
| `internet_gateway_id` | ID de l'Internet Gateway |

## Coût estimé

| Composant | Coût mensuel (eu-west-1) |
|-----------|--------------------------|
| VPC | Gratuit |
| NAT Gateway (1x) | ~$32/mois + $0.045/GB |
| NAT Gateway (3x HA) | ~$96/mois + $0.045/GB |
| Flow Logs (CloudWatch) | ~$0.50/GB ingéré |

> Utilisez `single_nat_gateway = true` pour les environnements non-production.

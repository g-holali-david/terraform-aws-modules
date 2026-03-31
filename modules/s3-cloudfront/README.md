# Module S3 + CloudFront

Déploie un bucket S3 avec une distribution CloudFront pour héberger des assets statiques (SPA, site web).

## Usage

```hcl
module "static" {
  source = "github.com/g-holali-david/terraform-aws-modules//modules/s3-cloudfront?ref=v1.0.0"

  bucket_name         = "myapp-static-prod"
  enable_cloudfront   = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"  # Régions EU + US uniquement

  # Optionnel : domaine custom avec ACM
  # acm_certificate_arn = "arn:aws:acm:us-east-1:123456:certificate/abc-123"

  tags = { Environment = "production" }
}
```

## Architecture

```
        Utilisateur
            │
            ▼
    ┌───────────────┐
    │  CloudFront   │ ← HTTPS, TLS 1.2+, compression
    │  Distribution │ ← Cache TTL: 1h par défaut
    └───────┬───────┘
            │ OAC (Origin Access Control)
            ▼
    ┌───────────────┐
    │   S3 Bucket   │ ← Privé, versionné, chiffré
    │               │ ← Pas d'accès public direct
    └───────────────┘
```

## Ressources créées

| Ressource | Condition |
|-----------|-----------|
| `aws_s3_bucket` | Toujours |
| `aws_s3_bucket_versioning` | Toujours |
| `aws_s3_bucket_server_side_encryption_configuration` | Toujours |
| `aws_s3_bucket_public_access_block` | Toujours |
| `aws_s3_bucket_policy` | `enable_cloudfront = true` |
| `aws_cloudfront_origin_access_control` | `enable_cloudfront = true` |
| `aws_cloudfront_distribution` | `enable_cloudfront = true` |

## Variables

| Nom | Type | Défaut | Description |
|-----|------|--------|-------------|
| `bucket_name` | `string` | — | Nom du bucket (globalement unique) |
| `enable_versioning` | `bool` | `true` | Activer le versioning S3 |
| `enable_cloudfront` | `bool` | `true` | Créer la distribution CloudFront |
| `default_root_object` | `string` | `index.html` | Objet racine |
| `price_class` | `string` | `PriceClass_100` | Classe de prix CF |
| `acm_certificate_arn` | `string` | `""` | ARN du certificat ACM (domaine custom) |
| `tags` | `map(string)` | `{}` | Tags |

## Outputs

| Nom | Description |
|-----|-------------|
| `bucket_id` | ID du bucket S3 |
| `bucket_arn` | ARN du bucket |
| `bucket_regional_domain_name` | Nom de domaine régional S3 |
| `cloudfront_distribution_id` | ID de la distribution CF |
| `cloudfront_domain_name` | Domaine CloudFront (xxx.cloudfront.net) |
| `cloudfront_arn` | ARN de la distribution CF |

## Sécurité

- **Bucket privé** : toutes les options de blocage d'accès public activées
- **OAC** : CloudFront accède à S3 via Origin Access Control (pas OAI legacy)
- **Chiffrement** : AES-256 côté serveur par défaut
- **TLS** : version minimale TLSv1.2_2021
- **HTTPS** : redirection HTTP → HTTPS automatique

## SPA Routing

Les erreurs 404 et 403 sont redirigées vers `index.html` pour supporter le client-side routing (React, Vue, Angular).

## Déploiement des fichiers

```bash
# Upload les fichiers
aws s3 sync ./build s3://myapp-static-prod --delete

# Invalider le cache CloudFront
aws cloudfront create-invalidation \
  --distribution-id EXXX \
  --paths "/*"
```

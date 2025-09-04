# Infrastructure Request Schema Design

## Philosophy

The infrastructure request schema is **simple**, **AWS-focused**, and designed for the **80% use case** - getting developers productive quickly with common infrastructure needs.

## Design Principles

1. **Simple Over Complex**: Only 4 resource types that cover most application needs
2. **AWS-Focused**: Built specifically for AWS, no multi-cloud abstractions
3. **Environment Scaling**: Resources automatically scale from dev → stage → prod
4. **Secure by Default**: Security best practices built-in
5. **Golden Path**: Opinionated defaults that work for most applications

## Core Resource Types (Only 4!)

### 1. **S3 Bucket** (`s3_bucket`)
```yaml
- type: s3_bucket
  name: uploads
  purpose: uploads  # uploads, static, backups
  public_access: false
```

**Use Cases**: File uploads, static website hosting, document storage
**Platform Implementation**: S3 with encryption, lifecycle policies, appropriate access controls

### 2. **RDS Database** (`rds_database`)
```yaml
- type: rds_database
  name: main
  engine: postgres  # postgres, mysql
  size: small  # small, medium, large
```

**Use Cases**: Application databases (optional - only if needed)
**Platform Implementation**: RDS with automatic sizing, backups, and security

### 3. **Secret** (`secret`)
```yaml
- type: secret
  name: app-secrets
  description: "Application secrets and API keys"
```

**Use Cases**: API keys, database credentials, third-party tokens
**Platform Implementation**: AWS Secrets Manager with proper IAM access

### 4. **IRSA Role** (`irsa_role`)
```yaml
- type: irsa_role
  name: myapp
  s3_buckets: [uploads, static]
  rds_databases: [main]
  secrets: [app-secrets]
```

**Use Cases**: Secure AWS access for Kubernetes pods (required for all apps)
**Platform Implementation**: IAM role with OIDC trust policy for EKS service accounts

## That's It!

Only 4 resource types. No queues, no caches, no search engines, no CDNs. Keep it simple.

## Environment-Specific Scaling

Resources automatically scale based on environment:

### Database Sizing
- **Dev**: `db.t3.micro` (minimal cost)
- **Stage**: `db.t3.small` (testing scale)  
- **Prod**: `db.r6g.large` (production performance)

### Storage & Retention
- **Dev**: 90-day retention, basic backups
- **Stage**: 6-month retention, enhanced monitoring
- **Prod**: Multi-year retention, multi-AZ, full backups

## Complete Example

```yaml
app: myapp
env: dev
namespace: myapp

resources:
  # File uploads
  - type: s3_bucket
    name: uploads
    purpose: uploads
    public_access: false

  # Static website
  - type: s3_bucket
    name: static
    purpose: static
    public_access: true

  # Database (optional)
  - type: rds_database
    name: main
    engine: postgres
    size: small

  # Secrets
  - type: secret
    name: app-secrets
    description: "Application secrets and API keys"

  # AWS permissions
  - type: irsa_role
    name: myapp
    s3_buckets: [uploads, static]
    rds_databases: [main]
    secrets: [app-secrets]
```

That's it! Simple, focused, and covers 80% of application needs.

## Benefits of This Simple Approach

1. **Easy to Understand**: Only 4 resource types to learn
2. **Fast to Deploy**: No complex configuration decisions
3. **Secure by Default**: Best practices built-in
4. **Environment Aware**: Automatically scales dev → stage → prod
5. **AWS Optimized**: Uses AWS services effectively
6. **Golden Path**: Opinionated defaults that work

## Implementation Strategy

1. **Start Here**: These 4 types cover most application needs
2. **Add Later**: Complex resources come later as separate requests
3. **Keep Simple**: Resist the urge to add more resource types
4. **Focus on 80%**: Perfect for MVP and early-stage applications

This schema is intentionally simple - it's a **starting point**, not a comprehensive platform.

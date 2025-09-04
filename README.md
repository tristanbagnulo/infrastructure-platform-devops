# Infrastructure Platform DevOps

> Platform team's infrastructure provisioning system for EKS-based applications.

This repository provides the infrastructure layer that works with the `golden-path-app-template` to enable self-service infrastructure provisioning for application teams.

## 🏗️ Architecture Overview

This repository provides:

- **Terraform Modules**: Secure, reusable infrastructure components
- **Infrastructure Runner**: Processes infrastructure requests from application teams
- **CI/CD Integration**: Jenkins pipelines for infrastructure provisioning
- **Platform Add-ons**: EKS cluster add-ons and configurations

## 📂 Repository Structure

```
infrastructure-platform-devops/
├── modules/                        # Reusable Terraform modules
│   ├── iam/irsa-role/             # IAM roles for service accounts
│   ├── s3-secure/                 # Secure S3 buckets
│   └── sqs-secure/                # Secure SQS queues
├── runner/                        # Infrastructure request processor
│   ├── schema/request.schema.json # Infrastructure request schema
│   ├── scripts/render.py          # Request → Terraform converter
│   ├── Jenkinsfile               # Infrastructure provisioning pipeline
│   └── main.tf                   # Terraform configuration
├── addons/                       # EKS cluster add-ons per environment
│   ├── dev/
│   ├── stage/
│   └── prod/
└── docs/                         # Documentation
```

## 🚀 Infrastructure Request Schema

Applications request infrastructure using a simple 4-resource schema:

```yaml
app: myapp
env: dev
namespace: myapp

resources:
  # S3 bucket for storage
  - type: s3_bucket
    name: uploads
    purpose: uploads
    public_access: false

  # Database (optional)
  - type: rds_database
    name: main
    engine: postgres
    size: small

  # Secrets management
  - type: secret
    name: app-secrets
    description: "Application secrets and API keys"

  # AWS permissions for Kubernetes pods
  - type: irsa_role
    name: myapp
    s3_buckets: [uploads]
    rds_databases: [main]
    secrets: [app-secrets]
```

## 🔧 How It Works

1. **App Team** commits infrastructure request to their app repository
2. **Jenkins Pipeline** triggers infrastructure runner 
3. **Runner** validates request and generates Terraform configuration
4. **Terraform** provisions AWS resources using secure modules
5. **Outputs** stored in SSM Parameter Store for app consumption

## 📋 Supported Resources

| Resource Type | Purpose | Auto-Scaling |
|---------------|---------|--------------|
| `s3_bucket` | File storage, static websites | ✅ Lifecycle policies by env |
| `rds_database` | Postgres/MySQL databases | ✅ Instance size by env |
| `secret` | API keys, credentials | ✅ Rotation in prod |
| `irsa_role` | Kubernetes → AWS permissions | ✅ Least privilege |

### Environment Scaling

Resources automatically scale by environment:

- **Dev**: Small instances, short retention, minimal cost
- **Stage**: Medium instances, longer retention, testing scale
- **Prod**: Large instances, long retention, high availability

## 🔐 Security Features

- **Least Privilege**: IRSA roles grant minimal required permissions
- **Encryption**: All data encrypted at rest and in transit
- **Secure by Default**: Security best practices built into modules
- **Audit Trail**: All infrastructure changes tracked in Git + Terraform

## 🛠️ Platform Team Usage

### Adding New Resource Types

1. Create Terraform module in `modules/`
2. Update `runner/schema/request.schema.json`
3. Add handling logic in `runner/scripts/render.py`
4. Test with application team

### Updating Existing Modules

1. Make changes to module in `modules/`
2. Test in dev environment
3. Update documentation
4. Communicate changes to application teams

## 🤝 Integration with App Template

This repository works seamlessly with the `golden-path-app-template`:

- **App teams** use the app template to deploy applications
- **Platform team** maintains this repository for infrastructure
- **CI/CD** automatically integrates the two repositories
- **External Secrets** syncs SSM parameters into Kubernetes secrets

## 📖 Documentation

- [Infrastructure Schema Design](docs/infrastructure-schema-design.md) - Detailed schema documentation
- [Runbooks](docs/runbooks/) - Operational procedures

---

**Maintained by the Platform Engineering Team**# GitOps Pipeline Test - Thu Sep  4 02:15:47 EDT 2025
# Trigger new workflow run

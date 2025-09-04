# Golden Path Infrastructure Platform

> **Self-contained infrastructure platform for automated application deployments using Kind Kubernetes and Jenkins CI/CD.**

This repository provides a complete infrastructure-as-code solution that enables application teams to deploy their applications with minimal infrastructure knowledge. It combines a Kind-based Kubernetes platform with Jenkins CI/CD and automated infrastructure provisioning.

## 🏗️ **Architecture Overview**

The Golden Path Infrastructure Platform consists of:

- **Kind Kubernetes Cluster**: Lightweight, production-ready Kubernetes running on AWS EC2
- **Jenkins CI/CD**: Automated deployment pipelines with Pipeline as Code
- **Infrastructure Runner**: Processes infrastructure requests from application teams
- **External Secrets Operator**: Secure secret management from AWS SSM
- **NGINX Ingress**: Load balancing and routing
- **Persistent Elastic IP**: Stable access point for the platform

## 📂 **Repository Structure**

```
infrastructure-platform-devops/
├── platform/                    # Platform deployment (Kind + Jenkins)
│   ├── main.tf                  # Terraform configuration for platform
│   ├── variables.tf             # Platform variables
│   ├── outputs.tf               # Platform outputs
│   ├── user-data-simple.sh      # EC2 user data script
│   ├── setup-platform.sh        # Platform setup automation
│   ├── install-jenkins-plugins.sh # Jenkins plugin installation
│   ├── deploy.sh                # Deployment script
│   └── README.md                # Platform-specific documentation
├── modules/                     # Reusable Terraform modules
│   ├── s3-secure/              # Secure S3 bucket module
│   ├── iam/irsa-role/          # IAM roles for service accounts
│   └── ec2-kind-cluster/       # Kind cluster module (legacy)
├── runner/                      # Infrastructure request processor
│   ├── main.tf                 # Runner Terraform configuration
│   ├── providers.tf            # Terraform providers
│   ├── schema/request.schema.json # Infrastructure request schema
│   └── scripts/render.py       # Request → Terraform converter
├── scripts/                     # Utility scripts
│   ├── pre-commit-lint.sh      # Pre-commit linting
│   ├── setup-github-secrets.sh # GitHub secrets setup
│   └── setup-jenkins-pipeline.sh # Jenkins pipeline setup
├── docs/                        # Documentation
│   ├── infrastructure-schema-design.md
│   ├── linting.md               # Linting standards
│   ├── repository-structure.md  # Structure documentation
│   └── runbooks/
├── Jenkinsfile                  # Main CI/CD pipeline
└── README.md                    # This file
```

## 🚀 **Quick Start**

### **Option 1: Containerized Development (Recommended)**
For a consistent experience across all platforms (Windows, macOS, Linux):

```bash
# Clone the repository
git clone https://github.com/your-org/infrastructure-platform-devops.git
cd infrastructure-platform-devops

# Set up the development environment
./scripts/dev-setup.sh setup

# Open development shell
./scripts/dev-setup.sh shell
```

**Prerequisites**: [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)

### **Option 2: Local Development**
For developers who prefer local tools:

**Prerequisites**:
1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (v1.0+)
3. **SSH key pair** in AWS EC2 (e.g., `golden-path-dev-new`)
4. **kubectl** >= 1.29.0
5. **Kind** >= 0.20.0
6. **Docker** (for Kind)

### **Deploy the Platform**

```bash
# Clone the repository
git clone <repository-url>
cd infrastructure-platform-devops

# Deploy the platform
cd platform
KEY_PAIR_NAME=golden-path-dev-new ./deploy.sh dev
```

### **Access the Platform**

After deployment, you'll have access to:

- **Jenkins UI**: `http://<elastic-ip>:8081`
- **Kubernetes API**: `https://<elastic-ip>:6443`
- **SSH Access**: `ssh -i ~/.ssh/<key-pair>.pem ec2-user@<elastic-ip>`

## 🔧 **How It Works**

### **1. Platform Deployment**
The platform deployment creates:
- **AWS EC2 instance** with persistent Elastic IP
- **Kind Kubernetes cluster** with proper configuration
- **Jenkins** with pre-installed plugins and port forwarding
- **External Secrets Operator** for secret management
- **NGINX Ingress** for load balancing

### **2. Infrastructure Request Processing**
Application teams request infrastructure using a simple schema:

```yaml
app: myapp
env: dev
namespace: myapp

resources:
  - type: s3_bucket
    name: uploads
    purpose: file_storage
    public_access: false
  - type: irsa_role
    name: myapp
    s3_buckets: [uploads]
```

### **3. Automated Deployment**
1. **App team** commits infrastructure request to their repository
2. **Jenkins pipeline** triggers infrastructure runner
3. **Runner** validates request and generates Terraform configuration
4. **Terraform** provisions AWS resources using secure modules
5. **Outputs** stored in SSM Parameter Store for app consumption

## 📋 **Supported Infrastructure Resources**

| Resource Type | Purpose | Auto-Scaling | Security |
|---------------|---------|--------------|----------|
| `s3_bucket` | File storage, static websites | ✅ Lifecycle policies | ✅ Encrypted, private by default |
| `irsa_role` | Kubernetes → AWS permissions | ✅ Least privilege | ✅ Minimal required permissions |

### **Environment Scaling**

Resources automatically scale by environment:
- **Dev**: Small instances, short retention, minimal cost
- **Stage**: Medium instances, longer retention, testing scale  
- **Prod**: Large instances, long retention, high availability

## 🔐 **Security Features**

- **Encrypted storage**: All EBS volumes are encrypted
- **IAM roles**: Least privilege access for platform operations
- **Security groups**: Restricted access to necessary ports only
- **SSH key authentication**: No password-based access
- **External Secrets**: Secure secret management from AWS SSM
- **Private by default**: All resources are private unless explicitly configured

## 🛠️ **Platform Team Usage**

### **Adding New Resource Types**

1. Create Terraform module in `modules/`
2. Update `runner/schema/request.schema.json`
3. Add handling logic in `runner/scripts/render.py`
4. Test with application team

### **Updating Platform Configuration**

1. Make changes to `platform/` directory
2. Test in dev environment
3. Update documentation
4. Deploy to production

## 🤝 **Integration with Application Teams**

This repository works seamlessly with the `golden-path-app-template`:

- **App teams** use the app template to deploy applications
- **Platform team** maintains this repository for infrastructure
- **CI/CD** automatically integrates the two repositories
- **External Secrets** syncs SSM parameters into Kubernetes secrets

## 📖 **Documentation**

### **Development**
- [Development Guide](docs/development/README.md) - Complete development documentation
- [Containerized Development](docs/development/containerized-development.md) - Docker-based development environment
- [Local Development](docs/development/local-development.md) - Local development setup
- [Contributing Guidelines](docs/development/contributing.md) - How to contribute
- [Code Quality Standards](docs/development/code-quality.md) - Linting and quality standards

### **Platform & Operations**
- [Platform Deployment Guide](platform/README.md) - Detailed platform setup
- [Infrastructure Schema Design](docs/infrastructure-schema-design.md) - Schema documentation
- [Runbooks](docs/runbooks/) - Operational procedures

## 🧪 **Testing**

### **Local Testing**

```bash
# Run linting
./scripts/pre-commit-lint.sh

# Test Terraform configuration
cd platform
terraform init
terraform validate
terraform plan
```

### **Full Platform Test**

```bash
# Deploy platform
cd platform
./deploy.sh dev

# Verify deployment
curl -I http://<elastic-ip>:8081

# Cleanup
terraform destroy
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Jenkins not accessible**: Check if port forwarding is running
   ```bash
   ssh -i ~/.ssh/<key-pair>.pem ec2-user@<elastic-ip> 'ps aux | grep port-forward'
   ```

2. **Setup incomplete**: Check setup logs
   ```bash
   ssh -i ~/.ssh/<key-pair>.pem ec2-user@<elastic-ip> 'tail -20 /home/ec2-user/setup.log'
   ```

3. **Kubernetes cluster issues**: Check cluster status
   ```bash
   ssh -i ~/.ssh/<key-pair>.pem ec2-user@<elastic-ip> 'kubectl get nodes'
   ```

## 💰 **Cost Optimization**

- **t3.medium instance**: Cost-effective for development workloads
- **Kind cluster**: No EKS costs, runs on single instance
- **GP3 storage**: Optimized for cost and performance
- **Elastic IP**: Stable access without additional costs
- **Auto-shutdown**: Can be stopped when not in use

## 🔄 **Destroy and Redeploy**

The platform is designed to be completely destroyable and redeployable:

```bash
# Destroy platform
cd platform
terraform destroy

# Redeploy from scratch
./deploy.sh dev
```

All automation, plugins, and configurations are built into the deployment process.

---

**Maintained by the Platform Engineering Team**# Demo trigger - Thu Sep  4 11:59:02 EDT 2025
# Test commit
# Pipeline Test - Thu Sep  4 13:24:13 EDT 2025

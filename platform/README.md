# Golden Path Platform Infrastructure

> **Self-contained platform deployment using Kind Kubernetes, Jenkins CI/CD, and automated setup.**

This directory contains the Terraform configuration for deploying the complete Golden Path platform infrastructure on AWS. The platform provides a production-ready development environment with automated setup and persistent access.

## 🏗️ **What This Deploys**

- **AWS EC2 Instance** with persistent Elastic IP
- **Kind Kubernetes Cluster** with proper configuration
- **Jenkins CI/CD** with pre-installed plugins and port forwarding
- **External Secrets Operator** for secure secret management
- **NGINX Ingress** for load balancing and routing
- **Automated Setup** that handles all configuration

## 🚀 **Quick Start**

### **Prerequisites**

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (v1.0+)
3. **SSH key pair** in AWS EC2 (e.g., `golden-path-dev-new`)

### **Deploy the Platform**

```bash
# Set your key pair name
export KEY_PAIR_NAME="golden-path-dev-new"

# Deploy the platform
./deploy.sh dev
```

### **Manual Deployment**

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan \
    -var="aws_region=us-east-2" \
    -var="environment=dev" \
    -var="key_pair_name=golden-path-dev-new"

# Apply deployment
terraform apply \
    -var="aws_region=us-east-2" \
    -var="environment=dev" \
    -var="key_pair_name=golden-path-dev-new"
```

## 🌐 **Platform Access**

After deployment, you'll have access to:

- **Jenkins UI**: `http://<elastic-ip>:8081`
- **Kubernetes API**: `https://<elastic-ip>:6443`
- **SSH Access**: `ssh -i ~/.ssh/<key-pair>.pem ec2-user@<elastic-ip>`

## 🤖 **Automated Setup**

The platform includes comprehensive automation that:

1. **Installs all dependencies** (Docker, kubectl, kind, helm, terraform, AWS CLI)
2. **Creates Kind cluster** with proper configuration
3. **Installs NGINX Ingress** for load balancing
4. **Deploys External Secrets Operator** for secret management
5. **Sets up Jenkins** with essential plugins
6. **Configures port forwarding** for easy access
7. **Creates workspace** for application deployments

### **Monitoring Setup Progress**

```bash
# Check if setup is complete
ssh -i ~/.ssh/<key-pair>.pem ec2-user@<elastic-ip> 'ls -la /home/ec2-user/.setup-complete'

# Monitor setup progress
ssh -i ~/.ssh/<key-pair>.pem ec2-user@<elastic-ip> 'tail -f /home/ec2-user/setup.log'
```

## ⚙️ **Configuration**

### **Environment Variables**

- `AWS_REGION`: AWS region (default: us-east-2)
- `ENVIRONMENT`: Environment name (default: dev)
- `KEY_PAIR_NAME`: EC2 key pair name (required)

### **Instance Configuration**

- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Storage**: 20GB GP3 encrypted volume
- **Elastic IP**: Persistent IP address for stable access
- **Security Groups**: Configured for Jenkins (8081), Kubernetes (6443), and SSH (22)

## 🔧 **Files Overview**

| File | Purpose |
|------|---------|
| `main.tf` | Main Terraform configuration |
| `variables.tf` | Input variables |
| `outputs.tf` | Output values |
| `user-data-simple.sh` | EC2 user data script |
| `setup-platform.sh` | Platform setup automation |
| `install-jenkins-plugins.sh` | Jenkins plugin installation |
| `deploy.sh` | Deployment script |

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

### **Manual Setup**

If automated setup fails, you can run it manually:

```bash
ssh -i ~/.ssh/<key-pair>.pem ec2-user@<elastic-ip>
cd /home/ec2-user
./setup-platform.sh
```

## 🧹 **Cleanup**

To destroy the platform:

```bash
terraform destroy \
    -var="aws_region=us-east-2" \
    -var="environment=dev" \
    -var="key_pair_name=golden-path-dev-new"
```

## 🏛️ **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS EC2 Instance                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Kind Cluster  │  │     Jenkins     │  │   NGINX     │ │
│  │   (Kubernetes)  │  │   (CI/CD)       │  │  Ingress    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ External Secrets│  │   AWS CLI       │                  │
│  │    Operator     │  │   Terraform     │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 **Security**

- **Encrypted storage**: All EBS volumes are encrypted
- **IAM roles**: Least privilege access for platform operations
- **Security groups**: Restricted access to necessary ports only
- **SSH key authentication**: No password-based access
- **Elastic IP**: Stable access without exposing instance IPs

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
terraform destroy

# Redeploy from scratch
./deploy.sh dev
```

All automation, plugins, and configurations are built into the deployment process.
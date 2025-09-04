# Golden Path Platform Infrastructure

This directory contains the Terraform configuration for deploying the Golden Path platform infrastructure on AWS.

## Overview

The Golden Path platform provides a complete infrastructure-as-code solution that includes:

- **Kind Kubernetes Cluster**: Lightweight Kubernetes for development and testing
- **Jenkins CI/CD**: Automated deployment pipelines with enhanced logging
- **NGINX Ingress**: Load balancing and routing
- **External Secrets Operator**: Secure secret management
- **AWS Integration**: Full AWS service integration for infrastructure provisioning

## Quick Start

### Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (v1.0+)
3. **SSH key pair** in AWS EC2 (e.g., `golden-path-dev-new`)

### Deploy the Platform

```bash
# Set your key pair name
export KEY_PAIR_NAME="golden-path-dev-new"

# Deploy the platform
./deploy.sh
```

### Manual Deployment

If you prefer manual control:

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

## Platform Access

After deployment, you'll have access to:

- **Jenkins UI**: `http://<public-ip>:8081`
- **Kubernetes API**: `https://<public-ip>:6443`
- **SSH Access**: `ssh -i ~/.ssh/<key-pair>.pem ec2-user@<public-ip>`

## Automated Setup

The platform includes automated setup that:

1. **Creates Kind cluster** with proper configuration
2. **Installs NGINX Ingress** for load balancing
3. **Deploys External Secrets Operator** for secret management
4. **Sets up Jenkins** with enhanced pipeline support
5. **Configures port forwarding** for easy access

### Monitoring Setup Progress

```bash
# Check if setup is complete
ssh -i ~/.ssh/<key-pair>.pem ec2-user@<public-ip> 'ls -la /home/ec2-user/.setup-complete'

# Monitor setup progress
ssh -i ~/.ssh/<key-pair>.pem ec2-user@<public-ip> 'tail -f /home/ec2-user/setup.log'
```

## Configuration

### Environment Variables

- `AWS_REGION`: AWS region (default: us-east-2)
- `ENVIRONMENT`: Environment name (default: dev)
- `KEY_PAIR_NAME`: EC2 key pair name (required)

### Instance Configuration

- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Storage**: 20GB GP3 encrypted volume
- **Security Groups**: Configured for Jenkins (8081), Kubernetes (6443), and SSH (22)

## Troubleshooting

### Common Issues

1. **Jenkins not accessible**: Check if port forwarding is running
   ```bash
   ssh -i ~/.ssh/<key-pair>.pem ec2-user@<public-ip> 'ps aux | grep port-forward'
   ```

2. **Setup incomplete**: Check setup logs
   ```bash
   ssh -i ~/.ssh/<key-pair>.pem ec2-user@<public-ip> 'tail -20 /home/ec2-user/setup.log'
   ```

3. **Kubernetes cluster issues**: Check cluster status
   ```bash
   ssh -i ~/.ssh/<key-pair>.pem ec2-user@<public-ip> 'kubectl get nodes'
   ```

### Manual Setup

If automated setup fails, you can run it manually:

```bash
ssh -i ~/.ssh/<key-pair>.pem ec2-user@<public-ip>
cd /home/ec2-user
./setup-platform.sh
```

## Cleanup

To destroy the platform:

```bash
terraform destroy \
    -var="aws_region=us-east-2" \
    -var="environment=dev" \
    -var="key_pair_name=golden-path-dev-new"
```

## Architecture

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

## Security

- **Encrypted storage**: All EBS volumes are encrypted
- **IAM roles**: Least privilege access for platform operations
- **Security groups**: Restricted access to necessary ports only
- **SSH key authentication**: No password-based access

## Cost Optimization

- **t3.medium instance**: Cost-effective for development workloads
- **Kind cluster**: No EKS costs, runs on single instance
- **GP3 storage**: Optimized for cost and performance
- **Auto-shutdown**: Can be stopped when not in use
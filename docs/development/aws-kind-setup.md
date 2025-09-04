# AWS Kind Cluster Setup Guide

> **Cost-Effective Alternative to EKS**: Run Kubernetes clusters on EC2 instances using kind instead of paying EKS management fees.

## 💰 **Cost Comparison**

| Solution | Monthly Cost | Use Case |
|----------|-------------|----------|
| **Kind on EC2** | ~$30-120/month | Demo, Development, Small Workloads |
| **AWS EKS** | ~$200-500/month | Production, Large Scale |

### **Kind on EC2 Breakdown:**
- **t3.medium**: $30/month (2 vCPU, 4GB) - Perfect for demos
- **t3.large**: $60/month (2 vCPU, 8GB) - Development workloads  
- **t3.xlarge**: $120/month (4 vCPU, 16GB) - Staging environments

**EKS charges $0.10/hour ($73/month) just for cluster management**, plus worker nodes!

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Account                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Default VPC                          ││
│  │                                                         ││
│  │  ┌─────────────────────────────────────────────────────┐││
│  │  │              EC2 Instance                           │││
│  │  │                                                     │││
│  │  │  ┌─────────────────────────────────────────────────┐│││
│  │  │  │            Docker Engine                        ││││
│  │  │  │                                                 ││││
│  │  │  │  ┌─────────────────────────────────────────────┐│││
│  │  │  │  │          Kind Cluster                       ││││
│  │  │  │  │  ┌─────────────────────────────────────────┐││││
│  │  │  │  │  │      Your Applications                  │││││
│  │  │  │  │  │   ┌─────────────────────────────────────┐│││││
│  │  │  │  │  │   │  photo-service                      ││││││
│  │  │  │  │  │   │  other-apps                         ││││││
│  │  │  │  │  │   └─────────────────────────────────────┘│││││
│  │  │  │  │  └─────────────────────────────────────────┘││││
│  │  │  │  └─────────────────────────────────────────────┐│││
│  │  │  └─────────────────────────────────────────────────┘││
│  │  └─────────────────────────────────────────────────────┘│
│  └─────────────────────────────────────────────────────────┘
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │     S3      │  │     RDS     │  │   Secrets   │         │
│  │   Buckets   │  │  Database   │  │  Manager    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### **1. Prerequisites**

```bash
# AWS CLI configured with appropriate permissions
aws configure

# Terraform installed
terraform --version

# SSH key pair created in AWS
aws ec2 create-key-pair --key-name my-golden-path-key \
  --query 'KeyMaterial' --output text > ~/.ssh/my-golden-path-key.pem
chmod 400 ~/.ssh/my-golden-path-key.pem
```

### **2. Create Infrastructure Request**

```yaml
# examples/my-app/infra/requests/aws-kind.yaml
app: my-app
env: dev
namespace: my-app

resources:
  # Kind cluster on EC2 (replaces EKS)
  - type: kind_cluster
    name: main
    instance_type: t3.medium  # Auto-scales by environment
    key_pair: my-golden-path-key

  # Standard AWS resources
  - type: s3_bucket
    name: uploads
    purpose: uploads
    public_access: false

  - type: rds_database
    name: main
    engine: postgres
    size: small

  - type: secret
    name: app-secrets
    description: "Application secrets"

  - type: irsa_role
    name: my-app
    s3_buckets: [uploads]
    rds_databases: [main]
    secrets: [app-secrets]
```

### **3. Generate and Apply Infrastructure**

```bash
cd infrastructure-platform-devops/runner

# Generate Terraform configuration
python3 scripts/render.py \
  ../../examples/my-app/infra/requests/aws-kind.yaml \
  123456789012 us-east-1 \
  arn:aws:iam::123456789012:oidc-provider/example \
  example \
  my-app-aws.tf.json

# Apply infrastructure
terraform init
terraform plan -var-file="my-app-aws.tf.json"
terraform apply -var-file="my-app-aws.tf.json"
```

### **4. Connect to Your Cluster**

```bash
# Get cluster connection info from Terraform outputs
CLUSTER_IP=$(terraform output -raw cluster_public_ip)
SSH_KEY=~/.ssh/my-golden-path-key.pem

# SSH to the cluster
ssh -i $SSH_KEY ubuntu@$CLUSTER_IP

# On the EC2 instance, get kubeconfig
kind get kubeconfig --name my-app-dev > ~/.kube/config

# Or from your local machine (port forward)
ssh -i $SSH_KEY -L 6443:localhost:6443 ubuntu@$CLUSTER_IP
kind get kubeconfig --name my-app-dev --internal > ~/.kube/config
```

## 🔧 **What Gets Created**

### **AWS Resources:**
- **EC2 Instance** (t3.medium) with Docker and kind pre-installed
- **Security Group** with Kubernetes ports (6443, 80, 443, 30000-32767)
- **S3 Buckets** for application storage
- **RDS Database** (db.t3.micro for dev)
- **Secrets Manager** entries
- **IAM Role** for pod-level AWS access
- **SSM Parameters** with cluster connection info

### **Kubernetes Resources (Auto-installed):**
- **NGINX Ingress Controller** for HTTP/HTTPS routing
- **External Secrets Operator** (when configured)
- **Metrics Server** for HPA support

## 🔐 **Security Features**

### **EC2 Security:**
- **Encrypted EBS volumes**
- **Security groups** with minimal required ports
- **SSH key-based access** only
- **Regular Ubuntu updates** via user-data script

### **Kubernetes Security:**
- **RBAC enabled** by default
- **Network policies** support
- **Pod security contexts** enforced
- **IRSA simulation** for AWS access

### **AWS IAM:**
- **Least privilege** IAM roles
- **Resource-specific** permissions
- **Environment isolation**

## 📊 **Environment Scaling**

| Environment | Instance Type | Monthly Cost | Use Case |
|-------------|---------------|--------------|----------|
| **dev** | t3.medium | ~$30 | Development, demos |
| **stage** | t3.large | ~$60 | Testing, staging |
| **prod** | t3.xlarge | ~$120 | Production workloads |

## 🎯 **Benefits Over EKS**

### **Cost Savings:**
- **No EKS management fee** ($73/month saved)
- **Smaller instances** for development
- **Single instance** vs multiple worker nodes

### **Simplicity:**
- **Faster setup** (5 minutes vs 20 minutes)
- **Direct SSH access** for debugging
- **No complex networking** (VPC, subnets, NAT gateways)

### **Development-Friendly:**
- **Local-like experience** on AWS
- **Easy cluster recreation**
- **Full root access** when needed

## ⚠️ **Limitations**

### **Not Suitable For:**
- **High availability** requirements (single instance)
- **Large scale** workloads (resource limits)
- **Production** critical applications

### **EKS Still Better For:**
- **Multi-AZ** deployments
- **Auto-scaling** worker nodes
- **AWS service integrations** (ALB, EBS CSI, etc.)
- **Compliance** requirements

## 🛠️ **Troubleshooting**

### **Common Issues:**

**SSH Connection Refused:**
```bash
# Check security group allows SSH from your IP
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

**Kind Cluster Not Starting:**
```bash
# SSH to instance and check Docker
ssh -i ~/.ssh/my-key.pem ubuntu@$CLUSTER_IP
sudo systemctl status docker
docker ps
kind get clusters
```

**Application Not Accessible:**
```bash
# Check NodePort services
kubectl get svc -A
# Port forward through SSH tunnel
ssh -i ~/.ssh/my-key.pem -L 8080:localhost:30080 ubuntu@$CLUSTER_IP
```

## 💡 **Tips for Success**

1. **Start Small**: Use t3.medium for initial testing
2. **Monitor Costs**: Set up billing alerts
3. **Backup Configs**: Store kubeconfig and SSH keys securely
4. **Use Spot Instances**: For non-critical workloads (60-90% savings)
5. **Regular Updates**: Keep the Ubuntu instance updated

## 🎯 **Perfect For:**

- **Interview Demos** (cost-effective, impressive)
- **Development Environments**
- **Learning Kubernetes** 
- **Proof of Concepts**
- **Small Team Projects**

This setup gives you a **real AWS-hosted Kubernetes cluster** for a fraction of EKS costs while maintaining the same developer experience! 🚀

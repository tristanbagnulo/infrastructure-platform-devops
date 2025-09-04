# Golden Path Platform on AWS

> Deploy the Golden Path platform itself on AWS using kind instead of EKS - cost-effective and powerful!

## 🎯 **What This Creates**

A complete Golden Path Developer Platform running on a single EC2 instance:

- **Kind Kubernetes cluster** (instead of expensive EKS)
- **Jenkins CI/CD** for automated deployments  
- **Infrastructure runner** to provision AWS resources
- **All platform components** (ingress, secrets, monitoring)
- **Real AWS integrations** (S3, RDS, Secrets Manager)

## 💰 **Cost: ~$60/month vs $200+/month for EKS**

## 🚀 **Quick Deploy**

### **Prerequisites**

1. **AWS CLI configured** with appropriate permissions
2. **SSH key pair** created in AWS
3. **Terraform installed** locally

```bash
# Create SSH key pair if you don't have one
aws ec2 create-key-pair --key-name golden-path-platform \
  --query 'KeyMaterial' --output text > ~/.ssh/golden-path-platform.pem
chmod 400 ~/.ssh/golden-path-platform.pem
```

### **Deploy Platform**

```bash
cd infrastructure-platform-devops/platform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="key_pair_name=golden-path-platform"

# Deploy platform
terraform apply -var="key_pair_name=golden-path-platform"
```

### **Complete Setup**

```bash
# Get connection info
PLATFORM_IP=$(terraform output -raw platform_public_ip)
SSH_COMMAND=$(terraform output -raw ssh_command)

# SSH to platform
$SSH_COMMAND

# Wait for base setup to complete
tail -f /var/log/user-data.log

# Complete platform setup (creates kind cluster, installs components)
./setup-platform.sh
```

## 🎯 **Access Your Platform**

After deployment:

- **SSH**: `ssh -i ~/.ssh/golden-path-platform.pem ubuntu@<PLATFORM_IP>`
- **Kubernetes**: `https://<PLATFORM_IP>:6443`
- **Jenkins**: `http://<PLATFORM_IP>:8080`

## 🏗️ **Platform Components**

### **Kubernetes Cluster (kind)**
- **Control plane** with all Kubernetes features
- **NGINX Ingress** for HTTP/HTTPS routing
- **External Secrets Operator** for AWS integration
- **Metrics server** for autoscaling

### **CI/CD (Jenkins)**
- **Automated pipelines** for app deployment
- **Infrastructure provisioning** integration
- **Git webhook** support

### **Infrastructure Runner**
- **Python script** to convert YAML → Terraform
- **AWS resource provisioning** (S3, RDS, Secrets)
- **IRSA role management**

## 🔧 **Using the Platform**

### **1. Deploy an Application**

```bash
# Clone your app template
git clone <your-golden-path-app-template> my-app
cd my-app

# Customize infrastructure request
cat > infra/requests/dev.yaml << EOF
app: my-app
env: dev
namespace: my-app

resources:
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
EOF

# Commit and push (triggers Jenkins pipeline)
git add .
git commit -m "Deploy my-app"
git push origin main
```

### **2. Manual Infrastructure Testing**

```bash
# SSH to platform
ssh -i ~/.ssh/golden-path-platform.pem ubuntu@<PLATFORM_IP>

# Navigate to runner
cd /home/ubuntu/workspace/infrastructure-platform-devops/runner

# Generate Terraform for your app
python3 scripts/render.py \
  ../../examples/my-app/infra/requests/dev.yaml \
  $(aws sts get-caller-identity --query Account --output text) \
  us-east-1 \
  arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/example \
  example \
  my-app.tf.json

# Apply infrastructure
terraform init
terraform apply -auto-approve
```

## 🔐 **Security & Permissions**

The platform instance has IAM permissions to:
- **Create/manage S3 buckets**
- **Create/manage RDS databases** 
- **Create/manage Secrets Manager entries**
- **Create/manage IAM roles** for applications
- **Read EC2/VPC information**

## 📊 **Monitoring & Logs**

```bash
# Platform setup logs
tail -f /var/log/user-data.log

# Kind cluster status
kind get clusters
kubectl get nodes

# Jenkins logs
kubectl logs -n jenkins deployment/jenkins

# Infrastructure runner logs
cd /home/ubuntu/workspace/infrastructure-platform-devops/runner
ls -la *.tf.json  # Generated configurations
```

## 🔧 **Troubleshooting**

### **Platform Not Starting**
```bash
# Check user-data execution
ssh -i ~/.ssh/your-key.pem ubuntu@<PLATFORM_IP>
tail -f /var/log/cloud-init-output.log
```

### **Kind Cluster Issues**
```bash
# Recreate cluster
kind delete cluster --name golden-path
./setup-platform.sh
```

### **Jenkins Not Accessible**
```bash
# Check Jenkins pod
kubectl get pods -n jenkins
kubectl logs -n jenkins deployment/jenkins
```

## 🎯 **Perfect For**

- **Interview demonstrations** 
- **Development environments**
- **Small team platforms**
- **Proof of concepts**
- **Learning Kubernetes + AWS**

## 🚀 **Next Steps**

1. **Configure Jenkins** with your Git repositories
2. **Set up webhooks** for automated deployments  
3. **Add monitoring** (Prometheus, Grafana)
4. **Customize** for your specific needs

Your Golden Path platform is now running on AWS with real cloud integrations! 🌟

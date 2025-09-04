# GitOps Infrastructure Deployment Guide

This document describes the complete GitOps pipeline for automated infrastructure deployment using GitHub Actions.

## 🎯 **Overview**

The GitOps pipeline automates the entire infrastructure deployment process:
- **Automatic linting** and validation on every commit
- **Environment-specific deployments** (dev, stage, prod)
- **Manual deployment controls** with approval workflows
- **Rollback and recovery** procedures
- **Comprehensive monitoring** and status reporting

## 🚀 **Pipeline Triggers**

### **Automatic Triggers:**
- **Push to `main`** → Deploy to production (with approvals)
- **Push to `develop`** → Deploy to development
- **Pull Request** → Lint and validate only

### **Manual Triggers:**
- **Workflow Dispatch** → Deploy to any environment
- **Environment-specific** → Deploy, destroy, or plan-only

## 🔧 **Setup Instructions**

### **1. Configure GitHub Secrets**

Navigate to your repository → Settings → Secrets and variables → Actions

Add the following secrets:

```bash
# AWS Credentials (from your SSO session)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...

# SSH Private Key (for platform access)
SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----...
```

### **2. Configure GitHub Environments**

The pipeline uses three environments with different protection rules:

#### **Development Environment:**
- ✅ 1 reviewer required
- ✅ No wait time
- ✅ Open access for testing

#### **Staging Environment:**
- ✅ 2 reviewers required
- ✅ 5-minute wait time
- ✅ Pre-production testing

#### **Production Environment:**
- ✅ 3 reviewers required
- ✅ 10-minute wait time
- ✅ Must pass dev deployment first
- ✅ Restricted IP access

### **3. Set Up SSH Key for Platform Access**

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/golden-path-dev-new

# Add public key to GitHub Secrets as SSH_PRIVATE_KEY
cat ~/.ssh/golden-path-dev-new.pub

# Keep private key for local access
```

## 📋 **Deployment Workflows**

### **Automatic Deployment (GitOps)**

#### **Development Deployment:**
```bash
# Trigger: Push to develop branch
git checkout develop
git add .
git commit -m "feat: add new infrastructure feature"
git push origin develop
```

#### **Production Deployment:**
```bash
# Trigger: Push to main branch
git checkout main
git merge develop
git push origin main
```

### **Manual Deployment**

#### **Deploy to Specific Environment:**
1. Go to Actions → GitOps Infrastructure Deployment
2. Click "Run workflow"
3. Select environment (dev/stage/prod)
4. Select action (deploy/destroy/plan-only)
5. Click "Run workflow"

#### **Destroy Infrastructure:**
1. Go to Actions → GitOps Infrastructure Deployment
2. Click "Run workflow"
3. Select environment to destroy
4. Select action: "destroy"
5. Click "Run workflow"

#### **Plan Only (No Deployment):**
1. Go to Actions → GitOps Infrastructure Deployment
2. Click "Run workflow"
3. Select environment
4. Select action: "plan-only"
5. Click "Run workflow"

## 🔍 **Pipeline Stages**

### **1. Lint and Validate**
- ✅ Terraform formatting check
- ✅ Terraform validation
- ✅ Jenkins pipeline syntax
- ✅ Security scanning
- ✅ Infrastructure plan generation

### **2. Environment Deployment**
- ✅ AWS credentials configuration
- ✅ Terraform initialization
- ✅ Infrastructure deployment
- ✅ Platform verification
- ✅ Application infrastructure setup

### **3. Post-Deployment Verification**
- ✅ SSH connectivity test
- ✅ Jenkins deployment verification
- ✅ Service status checks
- ✅ Deployment status reporting

## 📊 **Monitoring and Status**

### **GitHub Actions Dashboard:**
- View all deployment runs
- Check individual job status
- Review logs and outputs
- Monitor approval workflows

### **Deployment Status:**
Each deployment provides:
- Platform IP address
- Jenkins URL
- SSH access command
- Service status
- Resource information

### **Example Output:**
```
📊 Deployment Summary:
  - Environment: Development
  - Platform IP: 3.21.159.243
  - Jenkins URL: http://3.21.159.243:8081
  - SSH Command: ssh -i ~/.ssh/golden-path-dev-new.pem ec2-user@3.21.159.243
  - Status: ✅ Deployed Successfully
```

## 🛠 **Troubleshooting**

### **Common Issues:**

#### **1. Linting Failures:**
```bash
# Run local linting
./scripts/pre-commit-lint.sh

# Fix formatting issues
terraform fmt -recursive

# Fix Jenkins syntax
# Check for unescaped variables in shell commands
```

#### **2. AWS Credential Issues:**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check SSO session
aws sso login --profile sso-dev-admin

# Update GitHub secrets with new credentials
```

#### **3. SSH Connection Issues:**
```bash
# Test SSH connectivity
ssh -i ~/.ssh/golden-path-dev-new.pem ec2-user@<platform-ip>

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

#### **4. Terraform State Issues:**
```bash
# Check Terraform state
cd platform
terraform show

# Refresh state
terraform refresh

# Import existing resources if needed
terraform import aws_instance.platform <instance-id>
```

## 🔄 **Rollback Procedures**

### **Infrastructure Rollback:**
1. Go to Actions → GitOps Infrastructure Deployment
2. Select "destroy" action
3. Choose environment to rollback
4. Confirm destruction
5. Redeploy previous version

### **Code Rollback:**
```bash
# Revert to previous commit
git revert <commit-hash>
git push origin main

# Or reset to previous state
git reset --hard <commit-hash>
git push --force origin main
```

## 🔐 **Security Considerations**

### **Access Control:**
- ✅ Environment-specific permissions
- ✅ Required reviewers for production
- ✅ Wait timers for critical deployments
- ✅ IP restrictions for production

### **Secret Management:**
- ✅ AWS credentials in GitHub Secrets
- ✅ SSH keys encrypted in transit
- ✅ No hardcoded credentials in code
- ✅ Regular credential rotation

### **Audit Trail:**
- ✅ All deployments logged
- ✅ Reviewer approvals tracked
- ✅ Change history maintained
- ✅ Rollback actions recorded

## 📈 **Best Practices**

### **Development Workflow:**
1. **Create feature branch** from develop
2. **Make changes** and test locally
3. **Run linting** before committing
4. **Create pull request** for review
5. **Merge to develop** after approval
6. **Deploy to staging** for testing
7. **Merge to main** for production

### **Code Quality:**
- ✅ Always run `terraform fmt` before committing
- ✅ Use meaningful commit messages
- ✅ Test changes in dev environment first
- ✅ Review all infrastructure changes
- ✅ Keep user-data.sh under 16KB limit

### **Deployment Strategy:**
- ✅ Deploy to dev first
- ✅ Test thoroughly in staging
- ✅ Use blue-green deployments for production
- ✅ Monitor deployment status
- ✅ Have rollback plan ready

## 🎯 **Next Steps**

### **Immediate Actions:**
1. **Configure GitHub Secrets** with your AWS credentials
2. **Set up SSH key** for platform access
3. **Test the pipeline** with a small change
4. **Review environment settings** and adjust as needed

### **Future Enhancements:**
- **Slack/Teams notifications** for deployment status
- **Automated testing** of deployed infrastructure
- **Cost monitoring** and alerts
- **Backup and disaster recovery** procedures
- **Multi-region deployment** support

---

**🎉 Your GitOps pipeline is now ready for automated infrastructure deployment!**

The pipeline will catch issues before they reach production and provide a smooth, automated deployment experience across all environments.

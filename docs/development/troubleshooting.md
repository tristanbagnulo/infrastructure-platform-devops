# 🐛 Troubleshooting Guide

> **Solutions to common development and deployment issues in the Golden Path Infrastructure Platform.**

## 🎯 **Common Issues We've Encountered**

Based on our deployment experiences, here are the most common issues and their solutions:

## 🔧 **Terraform Issues**

### **Unescaped Variables in user-data.sh**
**Problem**: Terraform template variables not properly escaped in bash scripts.

**Error**:
```bash
Error: templatefile: failed to render template: template: user-data.sh:1:2: executing "user-data.sh" at <${aws_region}>: invalid syntax
```

**Solution**:
```bash
# ❌ Wrong - Terraform will try to interpolate this
region = ${aws_region}

# ✅ Correct - Double dollar sign escapes for Terraform
region = $${aws_region}
```

### **User-data Size Exceeding 16KB Limit**
**Problem**: AWS user-data scripts exceed the 16KB limit.

**Error**:
```bash
Error: expected length of user_data to be in the range (0 - 16384)
```

**Solution**:
```bash
# Check size
wc -c platform/user-data.sh

# If too large, split into multiple scripts
# 1. Minimal user-data.sh (clone repo, schedule setup)
# 2. setup-platform.sh (full setup logic)
# 3. install-jenkins-plugins.sh (Jenkins setup)
```

### **HCL Syntax Errors**
**Problem**: Invalid Terraform syntax in module definitions.

**Error**:
```bash
Error: Invalid expression
```

**Solution**:
```bash
# Run terraform fmt
terraform fmt -recursive

# Validate configuration
terraform validate
```

### **Missing Required Variables**
**Problem**: Terraform commands missing required variables.

**Error**:
```bash
Error: No value for required variable "aws_region"
```

**Solution**:
```bash
# Always specify required variables
terraform plan -var="aws_region=us-east-2" -var="environment=dev"
```

## 🐚 **Shell Script Issues**

### **ShellCheck Errors**
**Problem**: Shell script linting failures.

**Common Errors**:
- `SC2181`: Check exit code directly with `if mycmd;` not `if [ $? -eq 0 ]`
- `SC2154`: Variable referenced but not assigned
- `SC2086`: Double quote to prevent globbing

**Solutions**:
```bash
# ❌ Wrong
curl -X POST "$URL"
if [ $? -eq 0 ]; then
    echo "Success"
fi

# ✅ Correct
if curl -X POST "$URL"; then
    echo "Success"
fi

# For Terraform variables in scripts
# Add shellcheck disable comment
# shellcheck disable=SC2154
region = $${aws_region}
```

### **Permission Denied on Scripts**
**Problem**: Scripts not executable.

**Error**:
```bash
bash: ./scripts/pre-commit-lint.sh: Permission denied
```

**Solution**:
```bash
# Make scripts executable
chmod +x scripts/*.sh platform/*.sh
```

## 🚀 **Jenkins Pipeline Issues**

### **Groovy Syntax Errors**
**Problem**: Invalid Groovy syntax in Jenkinsfile.

**Error**:
```groovy
// ❌ Wrong - Missing quotes
def environment = dev

// ✅ Correct - Proper string
def environment = "dev"
```

### **Missing Plugin Dependencies**
**Problem**: Jenkins plugins not installed.

**Error**:
```bash
No such DSL method 'pipeline' found
```

**Solution**:
```bash
# Install required plugins
# - Pipeline
# - Git
# - GitHub
# - Kubernetes
```

### **SCM Configuration Issues**
**Problem**: Git integration not working.

**Error**:
```bash
Could not resolve hostname: github.com
```

**Solution**:
```bash
# Check network connectivity
ping github.com

# Verify SSH keys
ssh -T git@github.com
```

## 🔒 **Security Issues**

### **Hardcoded AWS Credentials**
**Problem**: AWS credentials in code.

**❌ Wrong**:
```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
```

**✅ Correct**:
```bash
# Use environment variables
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
```

### **Private Keys in Repository**
**Problem**: SSH keys committed to Git.

**Solution**:
```bash
# Add to .gitignore
echo "*.pem" >> .gitignore
echo "*.key" >> .gitignore

# Remove from Git history
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch *.pem' --prune-empty --tag-name-filter cat -- --all
```

## 🐳 **Docker Issues**

### **Container Build Failures**
**Problem**: Docker build fails.

**Error**:
```bash
ERROR: externally-managed-environment
```

**Solution**:
```dockerfile
# Use apt packages instead of pip
RUN apt-get install -y yamllint

# Or use virtual environment
RUN python3 -m venv /opt/venv && /opt/venv/bin/pip install pre-commit
```

### **Permission Issues in Container**
**Problem**: Permission denied in container.

**Error**:
```bash
Permission denied: /workspace/scripts/pre-commit-lint.sh
```

**Solution**:
```dockerfile
# Set proper ownership
RUN chown -R developer:developer /workspace
RUN chmod +x scripts/*.sh platform/*.sh
```

## 🌐 **Network Issues**

### **SSH Connection Failures**
**Problem**: Cannot connect to EC2 instance.

**Error**:
```bash
ssh: connect to host 18.223.242.198 port 22: Connection refused
```

**Solutions**:
```bash
# Check security group
aws ec2 describe-security-groups --group-ids sg-xxx

# Check instance status
aws ec2 describe-instances --instance-ids i-xxx

# Test connectivity
telnet 18.223.242.198 22
```

### **Port Forwarding Issues**
**Problem**: Jenkins not accessible via port forwarding.

**Error**:
```bash
curl: (7) Failed to connect to 18.223.242.198 port 8081
```

**Solutions**:
```bash
# Check if port forwarding is running
ps aux | grep kubectl

# Restart port forwarding
kubectl port-forward --address 0.0.0.0 -n jenkins svc/jenkins 8081:8080

# Check security group allows port 8081
```

## 🔍 **Debugging Techniques**

### **Enable Verbose Output**
```bash
# Terraform
export TF_LOG=DEBUG
terraform plan

# Shell scripts
bash -x scripts/pre-commit-lint.sh

# Docker
docker-compose logs dev-tools
```

### **Check Logs**
```bash
# EC2 instance logs
ssh -i ~/.ssh/key.pem ec2-user@IP "sudo tail -f /var/log/cloud-init-output.log"

# Jenkins logs
kubectl logs -n jenkins deployment/jenkins

# Container logs
docker-compose logs dev-tools
```

### **Test Individual Components**
```bash
# Test Terraform only
cd platform && terraform init && terraform validate

# Test ShellCheck only
shellcheck scripts/*.sh

# Test specific script
bash -n scripts/pre-commit-lint.sh
```

## 🆘 **Getting Help**

### **Check Documentation First**
1. [Code Quality Standards](code-quality.md)
2. [Containerized Development](containerized-development.md)
3. [Local Development](local-development.md)

### **Common Commands**
```bash
# Full linting check
./scripts/pre-commit-lint.sh

# Containerized linting
./scripts/dev-setup.sh lint

# Terraform validation
./scripts/dev-setup.sh validate

# Check all services
docker-compose ps
```

### **When to Ask for Help**
- Issue persists after trying solutions
- Error message is unclear
- Multiple components are failing
- Security-related concerns

### **Information to Include**
- Error message (exact text)
- Steps to reproduce
- Environment details (OS, versions)
- Relevant logs
- What you've already tried

---

**Remember: Most issues have been encountered before! Check this guide first. 🚀**

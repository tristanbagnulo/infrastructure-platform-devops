# Infrastructure Linting Guide

This document describes the comprehensive linting setup for the Golden Path infrastructure project, designed to catch common issues before they cause deployment failures.

## 🎯 **What We've Learned**

Based on our deployment experiences, we've identified several critical issues that can break infrastructure deployments:

### **Terraform Issues:**
- ❌ **Unescaped variables** in user-data.sh (`${var}` instead of `$${var}`)
- ❌ **Emoji characters** causing encoding issues in cloud-init
- ❌ **User-data size** exceeding AWS 16KB limit
- ❌ **HCL syntax errors** in module definitions
- ❌ **Missing required variables** in terraform commands

### **Jenkins Pipeline Issues:**
- ❌ **Groovy syntax errors** in pipeline scripts
- ❌ **Unescaped shell variables** in sh blocks
- ❌ **Missing plugin dependencies** for Pipeline functionality
- ❌ **SCM configuration** issues with Git integration

### **Security Issues:**
- ❌ **Hardcoded AWS credentials** in code
- ❌ **Private keys** committed to repository
- ❌ **Sensitive data** in configuration files

## 🔧 **Linting Setup**

### **1. GitHub Actions Workflow**

The `.github/workflows/lint-infrastructure.yml` file provides comprehensive CI/CD linting:

```yaml
# Runs on every push and PR
- Terraform format and validation
- Jenkins pipeline syntax checking
- Shell script linting with ShellCheck
- Security scanning for secrets
- Infrastructure plan testing
```

### **2. Pre-commit Hooks**

Install pre-commit hooks for local development:

```bash
# Install pre-commit
pip install pre-commit

# Install the hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

### **3. Manual Linting Script**

Run the comprehensive lint script manually:

```bash
# Make executable
chmod +x scripts/pre-commit-lint.sh

# Run linting
./scripts/pre-commit-lint.sh
```

## 📋 **Linting Checks**

### **Terraform Linting:**
- ✅ **Format validation** - Ensures consistent code formatting
- ✅ **Syntax validation** - Catches HCL syntax errors
- ✅ **Variable escaping** - Checks for proper `${var}` vs `$${var}` usage
- ✅ **Size limits** - Validates user-data.sh stays under 16KB
- ✅ **Character encoding** - Detects problematic emoji characters

### **Jenkins Pipeline Linting:**
- ✅ **Groovy syntax** - Validates pipeline script syntax
- ✅ **Parameter definitions** - Ensures proper parameter setup
- ✅ **Environment variables** - Checks for credential configuration
- ✅ **Shell escaping** - Validates shell command syntax

### **Shell Script Linting:**
- ✅ **ShellCheck** - Comprehensive shell script analysis
- ✅ **Best practices** - Follows shell scripting standards
- ✅ **Error handling** - Ensures proper error handling

### **Security Scanning:**
- ✅ **Secret detection** - Scans for hardcoded credentials
- ✅ **Private key detection** - Finds committed private keys
- ✅ **Password detection** - Identifies potential password leaks

## 🚀 **GitOps Integration**

### **Automated Deployment Pipeline:**

With proper GitOps setup, the following would be automated:

```yaml
# Example GitOps workflow
on:
  push:
    branches: [main]
    paths: ['infrastructure/**']

jobs:
  deploy:
    steps:
      - name: Lint Infrastructure
        run: ./scripts/pre-commit-lint.sh
      
      - name: Terraform Plan
        run: terraform plan -var-file=environments/prod.tfvars
      
      - name: Approve Deployment
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
      
      - name: Update Jenkins Configuration
        run: kubectl apply -f jenkins-config/
      
      - name: Verify Deployment
        run: ./scripts/verify-deployment.sh
```

### **What Would Be Automated:**
- ✅ **Infrastructure deployment** on git push
- ✅ **Jenkins configuration** updates
- ✅ **Plugin installation** and updates
- ✅ **Health checks** and validation
- ✅ **Rollback** on deployment failures

### **What Still Requires Manual Setup:**
- 🔐 **Initial AWS credentials** configuration
- 🔑 **SSH key management** and rotation
- 🌐 **DNS and domain** configuration
- 🚀 **Bootstrap** Jenkins job creation

## 🛠 **Common Issues and Fixes**

### **Issue: Terraform Template Variable Escaping**
```bash
# ❌ Wrong - causes Terraform template error
echo "Installing ${plugin_name}..."

# ✅ Correct - properly escaped
echo "Installing $${plugin_name}..."
```

### **Issue: User-data Size Limit**
```bash
# ❌ Too many plugins cause size limit exceeded
PLUGINS=(
    "plugin1" "plugin2" "plugin3" # ... 50+ plugins
)

# ✅ Reduced to essential plugins only
PLUGINS=(
    "workflow-aggregator"
    "git"
    "git-client"
    "scm-api"
    "credentials-binding"
)
```

### **Issue: Jenkins Pipeline Syntax**
```groovy
// ❌ Wrong - unescaped shell variables
sh 'echo "Value: ${VARIABLE}"'

// ✅ Correct - properly escaped
sh 'echo "Value: \${VARIABLE}"'
```

### **Issue: Security - Hardcoded Credentials**
```bash
# ❌ Wrong - hardcoded in code
AWS_ACCESS_KEY_ID=AKIA1234567890ABCDEF

# ✅ Correct - environment variable
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
```

## 📊 **Linting Results**

The linting system provides detailed feedback:

```
🔍 Running pre-commit infrastructure linting...
✅ Terraform formatting is correct
✅ Terraform validation passed
✅ user-data.sh syntax checks passed
✅ Jenkinsfile syntax checks passed
✅ All shell scripts passed linting
✅ Security scan completed
✅ Common issues check completed

📊 Pre-commit lint summary:
✅ All lint checks passed!

🚀 Ready to commit! Your infrastructure code looks good.
```

## 🔄 **Continuous Improvement**

The linting rules are continuously updated based on:

- **New deployment issues** encountered
- **Security vulnerabilities** discovered
- **Best practices** evolution
- **Tool updates** and new features

## 📚 **Additional Resources**

- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [ShellCheck Documentation](https://github.com/koalaman/shellcheck)
- [Pre-commit Hooks](https://pre-commit.com/)

## 🤝 **Contributing**

When adding new linting rules:

1. **Test thoroughly** with real scenarios
2. **Document the issue** being prevented
3. **Provide clear error messages** with fix suggestions
4. **Update this guide** with new rules
5. **Consider false positives** and edge cases

---

**Remember:** The goal is to catch issues early and provide clear guidance for fixes, not to block development unnecessarily.

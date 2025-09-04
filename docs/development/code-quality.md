# 🎨 Code Quality Standards

> **Comprehensive guide to maintaining code quality in the Golden Path Infrastructure Platform repository.**

## 🎯 **Overview**

This document outlines the code quality standards and practices for the Golden Path Infrastructure Platform repository. All code must meet these standards before being merged.

## 🔧 **Linting and Validation**

### **Automated Checks**
All code is automatically checked using our linting pipeline:

```bash
# Run all linting checks
./scripts/pre-commit-lint.sh

# Or using containerized tools
./scripts/dev-setup.sh lint
```

### **Required Tools**
- **Terraform**: Formatting and validation
- **ShellCheck**: Shell script linting
- **yamllint**: YAML file linting
- **Custom checks**: Security and best practices

## 📋 **Terraform Standards**

### **Formatting**
```bash
# Format all Terraform files
terraform fmt -recursive

# Check formatting without changes
terraform fmt -check -recursive
```

### **Validation**
```bash
# Validate Terraform configuration
cd platform
terraform init
terraform validate
```

### **Best Practices**

#### **Resource Naming**
```hcl
# Good: Descriptive and consistent
resource "aws_instance" "platform" {
  # ...
}

resource "aws_security_group" "platform" {
  # ...
}

# Bad: Unclear or inconsistent
resource "aws_instance" "web" {
  # ...
}

resource "aws_security_group" "sg1" {
  # ...
}
```

#### **Variable Definitions**
```hcl
# Good: Clear description and type
variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-2"
}

# Bad: Missing description or type
variable "region" {
  default = "us-east-2"
}
```

#### **Output Values**
```hcl
# Good: Descriptive output
output "platform_public_ip" {
  description = "Public IP address of the platform instance"
  value       = aws_eip.platform.public_ip
}

# Bad: Unclear output
output "ip" {
  value = aws_eip.platform.public_ip
}
```

#### **Resource Organization**
```hcl
# Good: Logical grouping with comments
# Platform Infrastructure
resource "aws_instance" "platform" {
  # ...
}

resource "aws_eip" "platform" {
  # ...
}

# Security Groups
resource "aws_security_group" "platform" {
  # ...
}
```

## 🐚 **Shell Script Standards**

### **ShellCheck Compliance**
All shell scripts must pass ShellCheck validation:

```bash
# Check individual script
shellcheck scripts/pre-commit-lint.sh

# Check all scripts
find . -name "*.sh" -type f -exec shellcheck {} \;
```

### **Best Practices**

#### **Error Handling**
```bash
#!/bin/bash
# Good: Proper error handling
set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipe failures

# Bad: No error handling
#!/bin/bash
# Script without error handling
```

#### **Variable Usage**
```bash
# Good: Proper variable quoting
if [ "$status" = "success" ]; then
    echo "Operation completed successfully"
fi

# Bad: Unquoted variables
if [ $status = success ]; then
    echo "Operation completed successfully"
fi
```

#### **Function Definitions**
```bash
# Good: Clear function with documentation
# Print status message with color coding
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
    esac
}

# Bad: Unclear function
print() {
    echo $1
}
```

#### **Exit Codes**
```bash
# Good: Explicit exit codes
if ! command -v terraform &> /dev/null; then
    echo "Terraform not found"
    exit 1
fi

# Bad: Implicit exit codes
if ! command -v terraform &> /dev/null; then
    echo "Terraform not found"
fi
```

## 📄 **Documentation Standards**

### **README Files**
- Clear, concise descriptions
- Up-to-date quick start guides
- Proper markdown formatting
- Examples and code snippets

### **Code Comments**
```bash
# Good: Clear, helpful comments
# Check if Docker is installed and available
if ! command -v docker &> /dev/null; then
    print_status "error" "Docker is not installed"
    exit 1
fi

# Bad: Obvious or unhelpful comments
# Check if docker exists
if ! command -v docker &> /dev/null; then
    print_status "error" "Docker is not installed"
    exit 1
fi
```

### **Inline Documentation**
```hcl
# Good: Explain complex logic
# Create Elastic IP for persistent IP address
# This ensures the platform IP doesn't change on restart
resource "aws_eip" "platform" {
  domain = "vpc"
  
  tags = {
    Name = "golden-path-platform-eip"
    Type = "platform-cluster"
  }
}
```

## 🔒 **Security Standards**

### **Secrets Management**
- Never commit secrets to version control
- Use environment variables for sensitive data
- Use AWS SSM Parameter Store for configuration
- Rotate secrets regularly

### **Input Validation**
```bash
# Good: Validate input parameters
if [ -z "$1" ]; then
    echo "Error: Environment parameter required"
    exit 1
fi

# Bad: No input validation
environment=$1
```

### **File Permissions**
```bash
# Good: Secure file permissions
chmod 600 ~/.ssh/private_key
chmod 644 ~/.ssh/public_key

# Bad: Insecure permissions
chmod 777 some_file
```

## 🧪 **Testing Standards**

### **Required Tests**
- [ ] Linting passes
- [ ] Terraform validation passes
- [ ] ShellCheck passes
- [ ] Documentation is updated

### **Test Coverage**
- All new features must have tests
- Bug fixes must include regression tests
- Documentation changes must be verified

## 📊 **Quality Gates**

### **Pre-commit Checks**
```bash
# All checks must pass before commit
./scripts/pre-commit-lint.sh
```

### **CI/CD Pipeline**
- Automated linting on every PR
- Terraform validation
- Security scanning
- Documentation checks

### **Manual Review**
- Code review by team members
- Architecture review for significant changes
- Security review for sensitive changes

## 🚫 **Common Issues to Avoid**

### **Terraform Issues**
- ❌ Hardcoded values instead of variables
- ❌ Missing resource descriptions
- ❌ Inconsistent naming conventions
- ❌ Missing error handling

### **Shell Script Issues**
- ❌ Unquoted variables
- ❌ Missing error handling
- ❌ Hardcoded paths
- ❌ Inconsistent indentation

### **Documentation Issues**
- ❌ Outdated information
- ❌ Missing examples
- ❌ Poor formatting
- ❌ Unclear instructions

## 🔧 **Tools and Configuration**

### **Editor Configuration**
```json
// .vscode/settings.json
{
  "terraform.format.enable": true,
  "terraform.validate.enable": true,
  "shellcheck.enable": true,
  "yaml.schemas": {
    "https://json.schemastore.org/github-workflow.json": ".github/workflows/*.yml"
  }
}
```

### **Pre-commit Hooks**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: terraform-fmt
        name: Terraform Format
        entry: terraform fmt -check -recursive
        language: system
        files: \.tf$
      
      - id: shellcheck
        name: ShellCheck
        entry: shellcheck
        language: system
        files: \.sh$
```

## 📈 **Continuous Improvement**

### **Regular Reviews**
- Monthly code quality reviews
- Quarterly tool updates
- Annual standard updates

### **Feedback Loop**
- Collect feedback from developers
- Monitor CI/CD pipeline metrics
- Track bug reports and issues

## 🎯 **Quick Reference**

### **Before Committing**
```bash
# 1. Format Terraform
terraform fmt -recursive

# 2. Validate Terraform
cd platform && terraform init && terraform validate

# 3. Run linting
./scripts/pre-commit-lint.sh

# 4. Check documentation
# Ensure README files are updated
```

### **Common Commands**
```bash
# Linting
./scripts/pre-commit-lint.sh

# Containerized linting
./scripts/dev-setup.sh lint

# Terraform validation
./scripts/dev-setup.sh validate

# Format check
./scripts/dev-setup.sh fmt
```

---

**Remember: Quality is everyone's responsibility! 🚀**

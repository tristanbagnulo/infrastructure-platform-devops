#!/bin/bash
# Pre-commit Infrastructure Lint Script
# This script runs local linting checks before commits

set -e

echo "🔍 Running pre-commit infrastructure linting..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
    esac
}

# Check if we're in the right directory
if [ ! -f "platform/main.tf" ]; then
    print_status "error" "Please run this script from the infrastructure-platform-devops directory"
    exit 1
fi

# 1. Terraform Format Check
echo "🔍 Checking Terraform formatting..."
if command -v terraform &> /dev/null; then
    if terraform fmt -check -recursive -diff; then
        print_status "success" "Terraform formatting is correct"
    else
        print_status "error" "Terraform files are not properly formatted"
        echo "Run 'terraform fmt -recursive' to fix formatting issues"
        exit 1
    fi
else
    print_status "warning" "Terraform not found, skipping format check"
fi

# 2. Terraform Validation
echo "🔍 Validating Terraform configuration..."
if command -v terraform &> /dev/null; then
    cd platform
    if terraform init -backend=false > /dev/null 2>&1; then
        if terraform validate > /dev/null 2>&1; then
            print_status "success" "Terraform validation passed"
        else
            print_status "error" "Terraform validation failed"
            terraform validate
            exit 1
        fi
    else
        print_status "error" "Terraform init failed"
        exit 1
    fi
    cd ..
else
    print_status "warning" "Terraform not found, skipping validation"
fi

# 3. Check for Terraform Syntax Issues
echo "🔍 Checking for common Terraform syntax issues..."

# Check for unescaped variables in user-data.sh
if [ -f "platform/user-data.sh" ]; then
    if grep -n "\${[^$]" platform/user-data.sh | grep -v "\$\${" | grep -v "plugin_name"; then
        print_status "error" "Found unescaped Terraform variables in user-data.sh"
        echo "Use \$\${variable} instead of \${variable} in bash scripts"
        exit 1
    fi
    
    # Check for emoji characters that might cause encoding issues
    if grep '[^[:print:][:space:]]' platform/user-data.sh; then
        print_status "error" "Found non-ASCII characters in user-data.sh"
        echo "Remove emoji characters to avoid encoding issues"
        exit 1
    fi
    
    # Check for user-data size limit
    user_data_size=$(wc -c < platform/user-data.sh)
    if [ "$user_data_size" -gt 16384 ]; then
        print_status "error" "user-data.sh is too large ($user_data_size bytes)"
        echo "AWS user-data limit is 16KB. Current size exceeds limit."
        exit 1
    fi
    
    print_status "success" "user-data.sh syntax checks passed"
fi

# 4. Jenkinsfile Validation
echo "🔍 Validating Jenkinsfile syntax..."
if [ -f "Jenkinsfile" ]; then
    # Check for common Groovy syntax issues
    # Look for specific problematic patterns in shell commands
    if grep -n "terraform.*\${[A-Z_]*}" Jenkinsfile | grep -v "\\\\\${"; then
        print_status "error" "Found unescaped variables in terraform commands"
        echo "Use \\\$ instead of \$ in terraform shell commands"
        exit 1
    fi
    
    if grep -n "ssh.*\${[A-Z_]*}" Jenkinsfile | grep -v "\\\\\${"; then
        print_status "error" "Found unescaped variables in ssh commands"
        echo "Use \\\$ instead of \$ in ssh shell commands"
        exit 1
    fi
    
    # Check for proper parameter definitions
    if ! grep -q 'parameters' Jenkinsfile; then
        print_status "warning" "No parameters defined in Jenkinsfile"
        echo "Consider adding parameters for environment, region, etc."
    fi
    
    # Check for proper environment variables
    if ! grep -q 'environment' Jenkinsfile; then
        print_status "warning" "No environment variables defined in Jenkinsfile"
        echo "Consider adding environment section for AWS credentials"
    fi
    
    print_status "success" "Jenkinsfile syntax checks passed"
fi

# 5. Shell Script Linting
echo "🔍 Linting shell scripts..."
if command -v shellcheck &> /dev/null; then
    find . -name "*.sh" -type f | while read -r script; do
        if shellcheck "$script"; then
            print_status "success" "ShellCheck passed for $script"
        else
            print_status "error" "ShellCheck found issues in $script"
            exit 1
        fi
    done
else
    print_status "warning" "ShellCheck not found, skipping shell script linting"
    echo "Install ShellCheck: brew install shellcheck (macOS) or apt-get install shellcheck (Ubuntu)"
fi

# 6. Security Scan
echo "🔍 Scanning for potential hardcoded secrets..."

# Check for AWS access keys
if grep -r "AKIA[0-9A-Z]{16}" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null; then
    print_status "error" "Found potential AWS access key in code"
    echo "Remove hardcoded credentials and use environment variables"
    exit 1
fi

# Check for private keys
if grep -r "BEGIN.*PRIVATE KEY" . --exclude-dir=.git --exclude-dir=node_modules --exclude="*.sh" --exclude="*.yml" --exclude="*.md" --exclude="GITOPS.md" 2>/dev/null; then
    print_status "error" "Found potential private key in code"
    echo "Remove private keys and use secure credential management"
    exit 1
fi

# Check for passwords
if grep -r "password.*=" . --exclude-dir=.git --exclude-dir=node_modules --exclude="*.md" 2>/dev/null; then
    print_status "warning" "Found potential password in code"
    echo "Consider using environment variables or secret management"
fi

print_status "success" "Security scan completed"

# 7. Check for common issues we've encountered
echo "🔍 Checking for common deployment issues..."

# Check if Jenkinsfile exists in root
if [ ! -f "Jenkinsfile" ]; then
    print_status "warning" "No Jenkinsfile found in root directory"
    echo "Consider adding a Jenkinsfile for Pipeline as Code"
fi

# Check if plugin installation script exists
if [ ! -f "platform/install-jenkins-plugins.sh" ]; then
    print_status "warning" "No Jenkins plugin installation script found"
    echo "Consider adding install-jenkins-plugins.sh for automated plugin management"
fi

# Check for proper module structure
if [ ! -d "modules" ]; then
    print_status "warning" "No modules directory found"
    echo "Consider organizing Terraform code into modules"
fi

print_status "success" "Common issues check completed"

# Summary
echo ""
echo "📊 Pre-commit lint summary:"
print_status "success" "All lint checks passed!"
echo ""
echo "🚀 Ready to commit! Your infrastructure code looks good."
echo ""
echo "💡 Tips for better GitOps:"
echo "  - Use 'terraform fmt -recursive' before committing"
echo "  - Test deployments in dev environment first"
echo "  - Keep user-data.sh under 16KB limit"
echo "  - Use environment variables for secrets"
echo "  - Validate Jenkinsfile syntax before pushing"

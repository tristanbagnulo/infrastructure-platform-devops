# 💻 Local Development Setup

> **Setting up a local development environment for the Golden Path Infrastructure Platform.**

## 🎯 **Overview**

This guide covers setting up a local development environment for contributing to the infrastructure platform repository. For most developers, we recommend using the [containerized development tools](containerized-development.md) for consistency.

## 📋 **Prerequisites**

### **Required Tools**
- [Git](https://git-scm.com/downloads) >= 2.30.0
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6.0
- [ShellCheck](https://github.com/koalaman/shellcheck) >= 0.8.0
- [jq](https://jqlang.github.io/jq/download/) >= 1.6.0

### **Optional Tools**
- [AWS CLI](https://aws.amazon.com/cli/) v2 (for testing deployments)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.29.0 (for testing)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/) >= 0.20.0 (for testing)
- [Docker](https://docs.docker.com/get-docker/) (for Kind testing)

## 🚀 **Setup Instructions**

### **1. Clone the Repository**
```bash
git clone https://github.com/your-org/infrastructure-platform-devops.git
cd infrastructure-platform-devops
```

### **2. Install Prerequisites**

#### **macOS (using Homebrew)**
```bash
# Install required tools
brew install terraform shellcheck jq git

# Verify installations
terraform --version
shellcheck --version
jq --version
git --version
```

#### **Ubuntu/Debian**
```bash
# Update package list
sudo apt-get update

# Install required tools
sudo apt-get install -y terraform shellcheck jq git

# Verify installations
terraform --version
shellcheck --version
jq --version
git --version
```

#### **Windows (using Chocolatey)**
```powershell
# Install required tools
choco install terraform shellcheck jq git

# Verify installations
terraform --version
shellcheck --version
jq --version
git --version
```

### **3. Configure Git**
```bash
# Set up Git configuration
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default branch
git config --global init.defaultBranch main
```

### **4. Verify Setup**
```bash
# Run linting to verify everything works
./scripts/pre-commit-lint.sh
```

## 🔧 **Development Workflow**

### **Daily Development**
```bash
# 1. Pull latest changes
git pull origin main

# 2. Create feature branch
git checkout -b feature/your-feature-name

# 3. Make changes
# Edit files as needed

# 4. Run linting
./scripts/pre-commit-lint.sh

# 5. Commit changes
git add .
git commit -m "feat: add your feature"

# 6. Push changes
git push origin feature/your-feature-name

# 7. Create pull request
# Use GitHub web interface or CLI
```

### **Testing Changes**
```bash
# Run all linting checks
./scripts/pre-commit-lint.sh

# Run Terraform validation
cd platform
terraform init
terraform validate
cd ..

# Run specific tests
# Add your test commands here
```

## 🛠️ **Available Scripts**

### **Linting and Validation**
```bash
# Run comprehensive linting
./scripts/pre-commit-lint.sh

# Run Terraform formatting
terraform fmt -recursive

# Run Terraform validation
cd platform && terraform init && terraform validate
```

### **Development Scripts**
```bash
# Setup GitHub secrets (if needed)
./scripts/setup-github-secrets.sh

# Setup Jenkins pipeline (if needed)
./scripts/setup-jenkins-pipeline.sh
```

## 🔍 **Code Quality Standards**

### **Terraform**
- Use `terraform fmt -recursive` before committing
- Run `terraform validate` after changes
- Follow [Terraform best practices](https://developer.hashicorp.com/terraform/language)

### **Shell Scripts**
- Use ShellCheck for linting
- Follow [Shell Script Best Practices](https://google.github.io/styleguide/shellguide.html)
- Use `set -e` for error handling

### **Documentation**
- Update README files when adding features
- Keep documentation in sync with code
- Use clear, concise language

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Terraform Not Found**
```bash
# Check if Terraform is installed
which terraform

# Install Terraform if missing
# See installation instructions above
```

#### **ShellCheck Not Found**
```bash
# Check if ShellCheck is installed
which shellcheck

# Install ShellCheck if missing
# See installation instructions above
```

#### **Permission Denied on Scripts**
```bash
# Make scripts executable
chmod +x scripts/*.sh platform/*.sh
```

#### **Git Configuration Issues**
```bash
# Check Git configuration
git config --list

# Set user configuration
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### **Getting Help**
- Check the [troubleshooting guide](troubleshooting.md)
- Review [common issues](troubleshooting.md#common-issues)
- Ask in the team Slack channel
- Create a [GitHub issue](https://github.com/your-org/infrastructure-platform-devops/issues)

## 📚 **Additional Resources**

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [ShellCheck Documentation](https://github.com/koalaman/shellcheck)
- [Git Documentation](https://git-scm.com/doc)
- [GitHub CLI Documentation](https://cli.github.com/manual/)

## 🎯 **Next Steps**

1. **Read the [Contributing Guidelines](contributing.md)**
2. **Set up [containerized development](containerized-development.md) (recommended)**
3. **Review the [code quality standards](code-quality.md)**
4. **Start contributing!**

---

**Happy coding! 🚀**

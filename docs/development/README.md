# 🛠️ Development Guide

> **Complete guide for developing and contributing to the Golden Path Infrastructure Platform repository.**

## 📚 **Development Documentation**

This directory contains all documentation related to developing and maintaining the infrastructure platform repository itself.

### **Getting Started**
- [Containerized Development Tools](containerized-development.md) - Docker-based development environment
- [Local Development Setup](local-development.md) - Setting up development environment locally
- [Repository Structure](../repository-structure.md) - Understanding the codebase organization

### **Development Workflows**
- [Contributing Guidelines](contributing.md) - How to contribute to the repository
- [Code Quality Standards](code-quality.md) - Linting, testing, and quality gates
- [Release Process](release-process.md) - How to create and manage releases

### **Testing & Validation**
- [Testing Strategy](testing-strategy.md) - Testing approach and methodologies
- [Local Testing Guide](local-testing.md) - Running tests locally
- [CI/CD Pipeline](ci-cd-pipeline.md) - Understanding the automated pipelines

### **Troubleshooting**
- [Troubleshooting Guide](troubleshooting.md) - Solutions to common development problems

## 🚀 **Quick Start for Developers**

### **Option 1: Containerized Development (Recommended)**
```bash
# Clone the repository
git clone https://github.com/your-org/infrastructure-platform-devops.git
cd infrastructure-platform-devops

# Build development tools
./scripts/dev-setup.sh build

# Run linting
./scripts/dev-setup.sh lint

# Run validation
./scripts/dev-setup.sh validate
```

### **Option 2: Local Development**
```bash
# Install prerequisites
# - Terraform >= 1.6.0
# - ShellCheck
# - Git

# Clone and setup
git clone https://github.com/your-org/infrastructure-platform-devops.git
cd infrastructure-platform-devops

# Run linting
./scripts/pre-commit-lint.sh
```

## 📋 **Development Checklist**

Before contributing, ensure you:

- [ ] Read the [Contributing Guidelines](contributing.md)
- [ ] Set up your [development environment](containerized-development.md)
- [ ] Run [linting and validation](code-quality.md)
- [ ] Write or update [tests](testing-strategy.md)
- [ ] Update [documentation](contributing.md#documentation)
- [ ] Follow [commit message conventions](contributing.md#commit-messages)

## 🔧 **Development Tools**

### **Containerized Tools**
- **Linting**: `./scripts/dev-setup.sh lint`
- **Validation**: `./scripts/dev-setup.sh validate`
- **Formatting**: `./scripts/dev-setup.sh fmt`
- **Shell**: `./scripts/dev-setup.sh shell`

### **Local Tools**
- **Linting**: `./scripts/pre-commit-lint.sh`
- **Terraform**: `terraform fmt -recursive && terraform validate`
- **ShellCheck**: `shellcheck scripts/*.sh platform/*.sh`

## 📖 **Repository Overview**

The Golden Path Infrastructure Platform repository is organized as follows:

```
infrastructure-platform-devops/
├── platform/                    # Platform deployment (Kind + Jenkins)
├── modules/                     # Reusable Terraform modules
├── runner/                      # Infrastructure request processor
├── scripts/                     # Utility scripts
├── docs/                        # Documentation
│   ├── development/             # Development documentation (this directory)
│   ├── infrastructure-schema-design.md
│   ├── linting.md
│   ├── repository-structure.md
│   └── runbooks/
├── .github/workflows/           # GitHub Actions workflows
├── Jenkinsfile                  # Main CI/CD pipeline
└── README.md                    # Main documentation
```

## 🎯 **Development Principles**

1. **Consistency**: Use containerized tools for consistent results
2. **Quality**: All code must pass linting and validation
3. **Documentation**: Keep documentation up-to-date
4. **Testing**: Test changes before committing
5. **Security**: Follow security best practices
6. **Simplicity**: Keep solutions simple and maintainable

## 🆘 **Getting Help**

- **Documentation**: Check the relevant docs in this directory
- **Issues**: [GitHub Issues](https://github.com/your-org/infrastructure-platform-devops/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/infrastructure-platform-devops/discussions)
- **Team**: Ask in the team Slack channel

---

**Happy developing! 🚀**

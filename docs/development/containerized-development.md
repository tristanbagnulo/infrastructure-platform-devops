# 🔧 Containerized Development Tools

> **Consistent linting and development tools across all platforms (Windows, macOS, Linux) with zero environment setup required.**

## 🎯 **Why Containerized Development Tools?**

The Golden Path Infrastructure Platform uses containerized development tools to ensure:

- **🔄 Consistency**: Identical linting results across all developer machines
- **🚀 Zero Setup**: No need to install Terraform, ShellCheck, etc.
- **🛡️ Isolation**: No conflicts with existing system tools
- **📱 Cross-Platform**: Works on Windows, macOS, and Linux
- **⚡ Lightweight**: Only includes tools needed for local development tasks

## 🚀 **Quick Start**

### **Prerequisites**
- [Docker](https://docs.docker.com/get-docker/) (latest version)
- [Docker Compose](https://docs.docker.com/compose/install/) (latest version)

### **First Time Setup**
```bash
# Clone the repository
git clone https://github.com/your-org/infrastructure-platform-devops.git
cd infrastructure-platform-devops

# Build the development tools container
./scripts/dev-setup.sh build
```

### **Daily Development**
```bash
# Run linting (most common task)
./scripts/dev-setup.sh lint

# Run Terraform validation
./scripts/dev-setup.sh validate

# Run Terraform formatting check
./scripts/dev-setup.sh fmt

# Open interactive shell for debugging
./scripts/dev-setup.sh shell
```

## 🛠️ **Available Commands**

| Command | Description |
|---------|-------------|
| `build` | Build the development tools container (first time) |
| `lint` | Run linting in the containerized environment |
| `validate` | Run Terraform validation in the containerized environment |
| `fmt` | Run Terraform formatting check in the containerized environment |
| `shell` | Open an interactive shell in the container |
| `clean` | Clean up containers and images |

## 📦 **What's Included**

The lightweight container includes only the essential development tools:

### **Core Tools**
- **Terraform** 1.6.0 - Infrastructure as Code validation and formatting
- **ShellCheck** - Shell script linting
- **yamllint** - YAML file linting
- **pre-commit** - Git hooks

### **Supporting Tools**
- **jq** - JSON processing
- **Git** - Version control
- **Python 3** - Scripting and automation
- **Bash** - Shell scripting

### **What's NOT Included**
- AWS CLI (not needed for local linting)
- kubectl (not needed for local linting)
- Kind (not needed for local linting)
- Docker CLI (not needed for local linting)

## 🔧 **Development Workflow**

### **1. Start Development**
```bash
# Start the environment
./scripts/dev-setup.sh start

# Open development shell
./scripts/dev-setup.sh shell
```

### **2. Work on Code**
```bash
# Inside the container, you have access to all tools
terraform --version
aws --version
kubectl version
shellcheck --version

# Run linting
./scripts/pre-commit-lint.sh

# Make changes to code
vim platform/main.tf
```

### **3. Test Changes**
```bash
# Run linting
./scripts/dev-setup.sh lint

# Run tests
./scripts/dev-setup.sh test

# Validate Terraform
cd platform && terraform init && terraform validate
```

### **4. Commit Changes**
```bash
# All git operations work normally
git add .
git commit -m "Your changes"
git push
```

## 🌐 **Volume Mounts**

The development environment mounts several volumes for seamless integration:

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `./` | `/workspace` | Repository code (live editing) |
| `~/.aws` | `/home/developer/.aws` | AWS credentials (read-only) |
| `~/.ssh` | `/home/developer/.ssh` | SSH keys (read-only) |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket for Kind |

## 🔐 **Security Considerations**

### **AWS Credentials**
- AWS credentials are mounted read-only from `~/.aws`
- No credentials are stored in the container image
- Use AWS SSO or IAM roles for authentication

### **SSH Keys**
- SSH keys are mounted read-only from `~/.ssh`
- No private keys are stored in the container image
- Use SSH agent forwarding if needed

### **Docker Socket**
- Docker socket is mounted for Kind functionality
- This allows the container to create other containers
- Only use trusted base images

## 🐛 **Troubleshooting**

### **Container Won't Start**
```bash
# Check Docker status
docker --version
docker-compose --version

# Check container logs
docker-compose logs dev-environment

# Restart the environment
./scripts/dev-setup.sh restart
```

### **Permission Issues**
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Rebuild the environment
./scripts/dev-setup.sh clean
./scripts/dev-setup.sh setup
```

### **Tool Not Found**
```bash
# Check if tools are installed
docker-compose exec dev-environment which terraform
docker-compose exec dev-environment which aws
docker-compose exec dev-environment which kubectl
```

### **Linting Fails**
```bash
# Run linting with verbose output
docker-compose exec dev-environment bash -c "set -x; ./scripts/pre-commit-lint.sh"
```

## 📚 **Advanced Usage**

### **Custom Environment Variables**
```bash
# Set custom environment variables
export AWS_REGION=us-west-2
export ENVIRONMENT=staging

# Start with custom variables
docker-compose up -d
```

### **Multiple Environments**
```bash
# Use different compose files
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### **Development with Kind**
```bash
# Start with Kind cluster
docker-compose --profile kind up -d

# Create Kind cluster
docker-compose exec dev-environment kind create cluster --name golden-path
```

## 🔄 **CI/CD Integration**

The containerized environment is also used in CI/CD:

```yaml
# .github/workflows/lint-infrastructure.yml
- name: Run Linting in Container
  run: |
    docker-compose -f docker-compose.yml run --rm dev-environment ./scripts/pre-commit-lint.sh
```

## 📖 **Best Practices**

1. **Always use the containerized environment** for development
2. **Run linting before committing** using `./scripts/dev-setup.sh lint`
3. **Test changes in the container** before pushing
4. **Keep the Dockerfile updated** with latest tool versions
5. **Use volume mounts** for credentials, not copying them
6. **Clean up regularly** using `./scripts/dev-setup.sh clean`

## 🆘 **Getting Help**

If you encounter issues:

1. Check the [troubleshooting section](#-troubleshooting)
2. Review the [Docker documentation](https://docs.docker.com/)
3. Check the [GitHub Issues](https://github.com/your-org/infrastructure-platform-devops/issues)
4. Ask in the team Slack channel

---

**Happy coding! 🚀**

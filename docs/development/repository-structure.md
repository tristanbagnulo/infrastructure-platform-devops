# Repository Structure Documentation

> **Comprehensive guide to the Golden Path Infrastructure Platform repository structure and file purposes.**

## 📂 **Directory Overview**

```
infrastructure-platform-devops/
├── platform/                    # Platform deployment (Kind + Jenkins)
├── modules/                     # Reusable Terraform modules
├── runner/                      # Infrastructure request processor
├── scripts/                     # Utility scripts
├── docs/                        # Documentation
│   ├── infrastructure-schema-design.md
│   ├── linting.md               # Linting standards
│   ├── repository-structure.md  # Structure documentation
│   └── runbooks/
├── Jenkinsfile                  # Main CI/CD pipeline
├── README.md                    # Main documentation
└── .gitignore                   # Git ignore rules
```

## 🏗️ **Platform Directory (`platform/`)**

**Purpose**: Contains all files needed to deploy the complete Golden Path platform infrastructure.

### **Core Files**

| File | Purpose | Type |
|------|---------|------|
| `main.tf` | Main Terraform configuration for platform deployment | Terraform |
| `variables.tf` | Input variables for platform configuration | Terraform |
| `outputs.tf` | Output values (IPs, URLs, SSH commands) | Terraform |
| `deploy.sh` | Deployment script with environment setup | Bash |

### **Automation Scripts**

| File | Purpose | Type |
|------|---------|------|
| `user-data-simple.sh` | EC2 user data script (installs dependencies) | Bash |
| `setup-platform.sh` | Platform setup automation (Kind, Jenkins, etc.) | Bash |
| `install-jenkins-plugins.sh` | Jenkins plugin installation and port forwarding | Bash |

### **Configuration Files**

| File | Purpose | Type |
|------|---------|------|
| `terraform.tfvars.example` | Example Terraform variables file | Terraform |
| `README.md` | Platform-specific documentation | Markdown |

## 🧩 **Modules Directory (`modules/`)**

**Purpose**: Reusable Terraform modules for infrastructure components.

### **Available Modules**

| Module | Purpose | Resources |
|--------|---------|-----------|
| `s3-secure/` | Secure S3 bucket with encryption and lifecycle | S3 bucket, encryption, lifecycle, CORS |
| `iam/irsa-role/` | IAM roles for Kubernetes service accounts | IAM role, policy, trust relationship |
| `ec2-kind-cluster/` | Kind cluster module (legacy) | EC2, Kind cluster |

### **Module Structure**

Each module follows this structure:
```
module-name/
├── main.tf      # Resource definitions
├── variables.tf # Input variables
└── outputs.tf   # Output values
```

## 🏃 **Runner Directory (`runner/`)**

**Purpose**: Infrastructure request processor that converts application requests into Terraform configurations.

### **Core Files**

| File | Purpose | Type |
|------|---------|------|
| `main.tf` | Runner Terraform configuration | Terraform |
| `providers.tf` | Terraform providers configuration | Terraform |
| `Jenkinsfile` | Infrastructure provisioning pipeline | Groovy |

### **Schema and Scripts**

| File | Purpose | Type |
|------|---------|------|
| `schema/request.schema.json` | Infrastructure request schema validation | JSON |
| `scripts/render.py` | Request → Terraform converter | Python |

## 🛠️ **Scripts Directory (`scripts/`)**

**Purpose**: Utility scripts for development, testing, and maintenance.

### **Available Scripts**

| Script | Purpose | Type |
|--------|---------|------|
| `pre-commit-lint.sh` | Pre-commit linting and validation | Bash |
| `setup-github-secrets.sh` | GitHub secrets configuration | Bash |
| `setup-jenkins-pipeline.sh` | Jenkins pipeline setup | Bash |

## 📚 **Documentation Directory (`docs/`)**

**Purpose**: Comprehensive documentation for the platform.

### **Documentation Files**

| File | Purpose | Type |
|-------|---------|------|
| `infrastructure-schema-design.md` | Detailed schema documentation | Markdown |
| `runbooks/` | Operational procedures | Markdown |

## 🔧 **Root Files**

### **Main Configuration**

| File | Purpose | Type |
|------|---------|------|
| `Jenkinsfile` | Main CI/CD pipeline for platform deployment | Groovy |
| `README.md` | Main repository documentation | Markdown |
| `docs/linting.md` | Code quality standards and linting rules | Markdown |
| `.gitignore` | Git ignore rules for the repository | Git |

## 🎯 **File Naming Conventions**

### **Terraform Files**
- `main.tf` - Main resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `providers.tf` - Provider configurations

### **Script Files**
- `*.sh` - Bash scripts
- `*.py` - Python scripts
- `*.groovy` - Groovy scripts (Jenkins)

### **Documentation Files**
- `README.md` - Directory documentation
- `*.md` - Markdown documentation files

### **Configuration Files**
- `*.json` - JSON configuration files
- `*.yaml` / `*.yml` - YAML configuration files
- `*.tfvars` - Terraform variable files

## 🔄 **Workflow Integration**

### **Platform Deployment Flow**
1. **Developer** runs `platform/deploy.sh`
2. **Terraform** provisions AWS resources using `platform/main.tf`
3. **User Data** script installs dependencies via `platform/user-data-simple.sh`
4. **Setup Script** configures platform via `platform/setup-platform.sh`
5. **Jenkins** becomes available with plugins via `platform/install-jenkins-plugins.sh`

### **Infrastructure Request Flow**
1. **App Team** commits infrastructure request to their repository
2. **Jenkins Pipeline** triggers `runner/Jenkinsfile`
3. **Schema Validation** validates request using `runner/schema/request.schema.json`
4. **Render Script** converts request to Terraform using `runner/scripts/render.py`
5. **Terraform** provisions resources using `modules/` components

## 🧹 **Maintenance Guidelines**

### **Adding New Modules**
1. Create directory in `modules/`
2. Follow module structure (`main.tf`, `variables.tf`, `outputs.tf`)
3. Update documentation
4. Test with sample configuration

### **Updating Platform**
1. Modify files in `platform/`
2. Test with `platform/deploy.sh dev`
3. Update `platform/README.md`
4. Deploy to production

### **Adding New Scripts**
1. Create script in `scripts/`
2. Make executable (`chmod +x`)
3. Add to documentation
4. Test functionality

## 🚨 **Important Notes**

### **Files to Never Commit**
- `*.tfstate` - Terraform state files
- `*.tfplan` - Terraform plan files
- `terraform.tfvars` - Variable files with secrets
- `.terraform/` - Terraform working directory

### **Files to Always Update**
- `README.md` - When adding new features
- `docs/linting.md` - When changing linting rules
- `docs/repository-structure.md` - When changing structure

### **Testing Requirements**
- All scripts must be tested before committing
- Terraform configurations must be validated
- Documentation must be updated for new features

---

**This structure is designed to be self-contained, maintainable, and easy to understand for both platform engineers and application teams.**

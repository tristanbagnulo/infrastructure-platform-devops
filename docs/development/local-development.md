# Local Development Environment

This guide covers setting up and managing the local development environment for the Golden Path Platform.

## Repository Structure

The repository is organized to separate production-ready code from local development tools:

### Main Repository (Committed)
- **Core GitOps files** - GitHub Actions workflows, Terraform configurations
- **Documentation** - This directory and other docs
- **Essential scripts** - Platform operation scripts in `scripts/`

### Temporary Directory (Ignored by Git)
Located in `temp/` directory, contains local development files:

#### `temp/ignored/` - Local Development Files
These files are useful for local development but should NOT be committed:

- **`setup-github-aws-oidc.sh`** - One-time setup for AWS OIDC authentication with GitHub Actions
- **`demo-setup.sh`** - Prepares environment for interview demos
- **`dev-setup.sh`** - Manages containerized development environment
- **`Dockerfile`** - Containerized development environment
- **`docker-compose.yml`** - Orchestrates development services
- **`.dockerignore`** - Excludes files from Docker build context

#### `temp/upstream/` - Future Organization
Reserved for future organizational needs.

## Usage

### Local Development
1. Use files in `temp/ignored/` for local development tasks
2. These files won't be deployed or shared via the repository
3. They are preserved for reference and local use only

### Production Deployment
1. Only files in the main repository are deployed via GitOps
2. The `temp/` directory is ignored by git and CI/CD pipelines
3. This ensures clean separation between development and production

## File Organization Principles

- **Production-ready code** goes in the main repository
- **Development tools** go in `temp/ignored/`
- **Documentation** stays in `docs/` for team access
- **Temporary organization** uses `temp/upstream/` if needed

This structure ensures the repository remains clean while preserving useful development tools locally.
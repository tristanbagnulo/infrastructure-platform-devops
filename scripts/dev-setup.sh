#!/bin/bash
# Golden Path Development Tools - Containerized Linting and Testing
# This script provides consistent development tools across all platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function for colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
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

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_status "error" "Docker is not installed"
        echo "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_status "error" "Docker Compose is not installed"
        echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_status "success" "Docker and Docker Compose are available"
}

# Build the development tools container
build_tools() {
    print_status "info" "Building development tools container..."
    
    if docker-compose build dev-tools; then
        print_status "success" "Development tools container built successfully"
    else
        print_status "error" "Failed to build development tools container"
        exit 1
    fi
}

# Run linting in container
run_linting() {
    print_status "info" "Running linting in containerized environment..."
    
    if docker-compose run --rm dev-tools ./scripts/pre-commit-lint.sh; then
        print_status "success" "Linting passed in containerized environment"
    else
        print_status "error" "Linting failed in containerized environment"
        exit 1
    fi
}

# Run Terraform validation in container
run_terraform_validate() {
    print_status "info" "Running Terraform validation in containerized environment..."
    
    if docker-compose run --rm dev-tools bash -c "cd platform && terraform init && terraform validate"; then
        print_status "success" "Terraform validation passed"
    else
        print_status "error" "Terraform validation failed"
        exit 1
    fi
}

# Run Terraform formatting check in container
run_terraform_fmt() {
    print_status "info" "Running Terraform formatting check in containerized environment..."
    
    if docker-compose run --rm dev-tools bash -c "terraform fmt -check -recursive"; then
        print_status "success" "Terraform formatting is correct"
    else
        print_status "error" "Terraform files are not properly formatted"
        echo "Run 'terraform fmt -recursive' to fix formatting issues"
        exit 1
    fi
}

# Open interactive shell in container
open_shell() {
    print_status "info" "Opening development tools shell..."
    docker-compose run --rm dev-tools bash
}

# Clean up containers and images
clean_up() {
    print_status "info" "Cleaning up development tools..."
    docker-compose down --rmi all --volumes --remove-orphans
    print_status "success" "Development tools cleaned up"
}

# Show usage information
show_usage() {
    echo "Golden Path Development Tools"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build     - Build the development tools container"
    echo "  lint      - Run linting in containerized environment"
    echo "  validate  - Run Terraform validation in containerized environment"
    echo "  fmt       - Run Terraform formatting check in containerized environment"
    echo "  shell     - Open an interactive shell in the container"
    echo "  clean     - Clean up containers and images"
    echo ""
    echo "Examples:"
    echo "  $0 build     # Build the container (first time)"
    echo "  $0 lint      # Run linting"
    echo "  $0 validate  # Run Terraform validation"
    echo "  $0 shell     # Open interactive shell"
    echo ""
    echo "Quick start:"
    echo "  $0 build && $0 lint  # Build and run linting"
}

# Main script logic
case "${1:-help}" in
    "build")
        check_docker
        build_tools
        ;;
    "lint")
        check_docker
        run_linting
        ;;
    "validate")
        check_docker
        run_terraform_validate
        ;;
    "fmt")
        check_docker
        run_terraform_fmt
        ;;
    "shell")
        check_docker
        open_shell
        ;;
    "clean")
        clean_up
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        print_status "error" "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac

#!/bin/bash
# Quick Demo Setup for Interview
# This script prepares everything needed for the interview demonstration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
JENKINS_URL="http://18.223.242.198:8081"
PLATFORM_IP="18.223.242.198"

echo "🚀 Golden Path Infrastructure Platform - Interview Demo Setup"
echo "=============================================================="
echo ""

# 1. Check platform status
print_status "info" "Checking platform status..."
if curl -s "$JENKINS_URL" > /dev/null; then
    print_status "success" "Jenkins is running at $JENKINS_URL"
else
    print_status "error" "Jenkins is not accessible. Check if platform is running."
    exit 1
fi

# 2. Run linting to show code quality
print_status "info" "Running linting to demonstrate code quality..."
if ./scripts/pre-commit-lint.sh; then
    print_status "success" "All linting checks passed!"
else
    print_status "warning" "Some linting issues found, but continuing with demo"
fi

# 3. Set up Jenkins GitHub integration
print_status "info" "Setting up Jenkins GitHub integration..."
if ./scripts/setup-jenkins-github.sh; then
    print_status "success" "Jenkins GitHub integration ready!"
else
    print_status "warning" "Jenkins setup had issues, but continuing with demo"
fi

echo ""
echo "🎯 DEMO READY! Here's what to show in your interview:"
echo "====================================================="
echo ""
echo "1. 📊 PLATFORM OVERVIEW:"
echo "   - Jenkins Dashboard: $JENKINS_URL"
echo "   - Platform IP: $PLATFORM_IP"
echo "   - Repository: https://github.com/tristanbagnulo/infrastructure-platform-devops"
echo ""
echo "2. 🔧 CODE QUALITY DEMONSTRATION:"
echo "   - Show containerized development tools: ./scripts/dev-setup.sh lint"
echo "   - Show consistent linting across platforms"
echo "   - Show comprehensive documentation in docs/development/"
echo ""
echo "3. 🚀 JENKINS PIPELINE DEMONSTRATION:"
echo "   - Show pipeline job: golden-path-infrastructure-pipeline"
echo "   - Trigger a manual build"
echo "   - Show build logs and progress"
echo "   - Show GitHub integration"
echo ""
echo "4. 📚 REPOSITORY FEATURES:"
echo "   - Self-contained platform deployment"
echo "   - Containerized development environment"
echo "   - Comprehensive documentation"
echo "   - GitOps workflow ready"
echo ""
echo "5. 🎪 DEMO SCRIPT COMMANDS:"
echo "   # Show linting"
echo "   ./scripts/pre-commit-lint.sh"
echo ""
echo "   # Show containerized tools"
echo "   ./scripts/dev-setup.sh lint"
echo ""
echo "   # Show Jenkins integration"
echo "   ./scripts/setup-jenkins-github.sh"
echo ""
echo "6. 📖 KEY DOCUMENTATION:"
echo "   - docs/development/README.md - Complete development guide"
echo "   - docs/development/containerized-development.md - Docker setup"
echo "   - docs/development/troubleshooting.md - Common issues"
echo "   - platform/README.md - Platform deployment guide"
echo ""
echo "🎉 Good luck with your interview! 🎉"

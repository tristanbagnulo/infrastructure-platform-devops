#!/bin/bash
# GitHub Secrets Setup Script
# This script helps configure the required secrets for GitOps deployment

set -e

echo "🔧 GitHub Secrets Setup for GitOps Deployment"
echo "=============================================="

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
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_status "error" "AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_status "warning" "GitHub CLI not found. You'll need to set secrets manually."
    echo "Install GitHub CLI: brew install gh (macOS) or apt install gh (Ubuntu)"
    echo ""
fi

echo "📋 Required GitHub Secrets:"
echo "  - AWS_ACCESS_KEY_ID"
echo "  - AWS_SECRET_ACCESS_KEY"
echo "  - AWS_SESSION_TOKEN"
echo "  - SSH_PRIVATE_KEY"
echo ""

# Get AWS credentials
print_status "info" "Getting AWS credentials..."

# Check if AWS SSO is configured
if aws sts get-caller-identity &> /dev/null; then
    print_status "success" "AWS credentials are valid"
    
    # Get current AWS credentials
    AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
    AWS_SESSION_TOKEN=$(aws configure get aws_session_token)
    
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        print_status "error" "Could not retrieve AWS credentials"
        echo "Please run: aws sso login --profile sso-dev-admin"
        exit 1
    fi
    
    print_status "success" "AWS credentials retrieved successfully"
else
    print_status "error" "AWS credentials not found or expired"
    echo "Please run: aws sso login --profile sso-dev-admin"
    exit 1
fi

# Check for SSH key
print_status "info" "Checking for SSH key..."

SSH_KEY_PATH="$HOME/.ssh/golden-path-dev-new"
if [ -f "$SSH_KEY_PATH" ]; then
    print_status "success" "SSH key found at $SSH_KEY_PATH"
    SSH_PRIVATE_KEY=$(cat "$SSH_KEY_PATH")
else
    print_status "warning" "SSH key not found at $SSH_KEY_PATH"
    echo "Generating new SSH key pair..."
    
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "golden-path-dev-new"
    print_status "success" "SSH key generated successfully"
    
    SSH_PRIVATE_KEY=$(cat "$SSH_KEY_PATH")
fi

# Display secrets (for manual setup)
echo ""
echo "🔐 GitHub Secrets to Configure:"
echo "==============================="
echo ""
echo "1. AWS_ACCESS_KEY_ID:"
echo "$AWS_ACCESS_KEY_ID"
echo ""
echo "2. AWS_SECRET_ACCESS_KEY:"
echo "$AWS_SECRET_ACCESS_KEY"
echo ""
echo "3. AWS_SESSION_TOKEN:"
echo "$AWS_SESSION_TOKEN"
echo ""
echo "4. SSH_PRIVATE_KEY:"
echo "$SSH_PRIVATE_KEY"
echo ""

# Try to set secrets automatically with GitHub CLI
if command -v gh &> /dev/null; then
    print_status "info" "GitHub CLI found. Attempting to set secrets automatically..."
    
    # Check if user is authenticated
    if gh auth status &> /dev/null; then
        print_status "success" "GitHub CLI authenticated"
        
        # Set secrets
        echo "$AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID
        echo "$AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY
        echo "$AWS_SESSION_TOKEN" | gh secret set AWS_SESSION_TOKEN
        echo "$SSH_PRIVATE_KEY" | gh secret set SSH_PRIVATE_KEY
        
        print_status "success" "GitHub secrets set successfully!"
    else
        print_status "warning" "GitHub CLI not authenticated"
        echo "Run: gh auth login"
        echo "Then re-run this script"
    fi
else
    print_status "info" "Setting secrets manually..."
    echo ""
    echo "📝 Manual Setup Instructions:"
    echo "1. Go to your GitHub repository"
    echo "2. Navigate to Settings → Secrets and variables → Actions"
    echo "3. Click 'New repository secret' for each secret above"
    echo "4. Copy and paste the values from above"
    echo ""
fi

# Display next steps
echo "🚀 Next Steps:"
echo "=============="
echo "1. Verify secrets are set in GitHub repository settings"
echo "2. Test the pipeline with a small change:"
echo "   git checkout develop"
echo "   echo '# Test change' >> README.md"
echo "   git add README.md"
echo "   git commit -m 'test: trigger GitOps pipeline'"
echo "   git push origin develop"
echo ""
echo "3. Monitor the deployment in GitHub Actions"
echo "4. Check the deployment status and logs"
echo ""

print_status "success" "GitHub Secrets setup complete!"
echo ""
echo "💡 Pro Tips:"
echo "  - Keep your AWS credentials up to date"
echo "  - Rotate SSH keys regularly"
echo "  - Monitor deployment logs for issues"
echo "  - Test changes in dev environment first"

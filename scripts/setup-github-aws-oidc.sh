#!/bin/bash
# Setup AWS OIDC for GitHub Actions
# This script creates the necessary AWS resources for GitHub Actions to assume an IAM role

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
GITHUB_ORG="tristanbagnulo"
GITHUB_REPO="infrastructure-platform-devops"
AWS_REGION="us-east-2"
ROLE_NAME="GitHubActions-GoldenPath"

print_status "info" "Setting up AWS OIDC for GitHub Actions..."

# 1. Create OIDC Identity Provider
print_status "info" "Creating OIDC Identity Provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com \
  --region $AWS_REGION \
  --profile sso-dev-admin || print_status "warning" "OIDC provider may already exist"

# 2. Create IAM Role for GitHub Actions
print_status "info" "Creating IAM Role for GitHub Actions..."

# Create trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::405474549744:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://trust-policy.json \
  --region $AWS_REGION \
  --profile sso-dev-admin || print_status "warning" "Role may already exist"

# 3. Attach AdministratorAccess policy
print_status "info" "Attaching AdministratorAccess policy..."
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
  --region $AWS_REGION \
  --profile sso-dev-admin || print_status "warning" "Policy may already be attached"

# 4. Get the role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text --profile sso-dev-admin)

print_status "success" "AWS OIDC setup complete!"
echo ""
echo "🎯 Next Steps:"
echo "1. Update your GitHub Actions workflow to use OIDC:"
echo "   - Remove AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN secrets"
echo "   - Add AWS_ROLE_ARN secret with value: $ROLE_ARN"
echo "   - Update workflow to use 'aws-actions/configure-aws-credentials@v4' with role"
echo ""
echo "2. Update GitHub repository secrets:"
echo "   - Go to: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/settings/secrets/actions"
echo "   - Add secret: AWS_ROLE_ARN = $ROLE_ARN"
echo "   - Add secret: AWS_REGION = $AWS_REGION"
echo ""
echo "3. Update workflow file to use OIDC instead of access keys"

# Cleanup
rm -f trust-policy.json

print_status "success" "Setup complete! Ready for real AWS deployment."

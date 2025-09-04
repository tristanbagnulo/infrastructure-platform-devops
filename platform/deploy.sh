#!/bin/bash
set -e

# Golden Path Platform Deployment Script
# This script deploys the Golden Path platform infrastructure to AWS

echo "🚀 Deploying Golden Path Platform to AWS..."

# Check if required variables are set
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-2"
    echo "Using default AWS region: $AWS_REGION"
fi

if [ -z "$ENVIRONMENT" ]; then
    ENVIRONMENT="dev"
    echo "Using default environment: $ENVIRONMENT"
fi

if [ -z "$KEY_PAIR_NAME" ]; then
    echo "❌ Error: KEY_PAIR_NAME environment variable is required"
    echo "Usage: KEY_PAIR_NAME=your-key-pair ./deploy.sh"
    exit 1
fi

echo "📋 Deployment Configuration:"
echo "  • AWS Region: $AWS_REGION"
echo "  • Environment: $ENVIRONMENT"
echo "  • Key Pair: $KEY_PAIR_NAME"
echo ""

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan \
    -var="aws_region=$AWS_REGION" \
    -var="environment=$ENVIRONMENT" \
    -var="key_pair_name=$KEY_PAIR_NAME"

# Ask for confirmation
echo ""
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Apply deployment
echo "🏗️ Deploying infrastructure..."
terraform apply -auto-approve \
    -var="aws_region=$AWS_REGION" \
    -var="environment=$ENVIRONMENT" \
    -var="key_pair_name=$KEY_PAIR_NAME"

# Get outputs
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Platform Information:"
terraform output

echo ""
echo "🎯 Next Steps:"
echo "1. Wait 5-10 minutes for the platform to fully initialize"
echo "2. SSH to the instance: $(terraform output -raw ssh_command)"
echo "3. Check setup progress: tail -f /home/ec2-user/setup.log"
echo "4. Access Jenkins: $(terraform output -raw jenkins_url)"
echo ""
echo "🔍 To check if setup is complete:"
echo "   ssh -i ~/.ssh/$KEY_PAIR_NAME.pem ec2-user@$(terraform output -raw platform_public_ip) 'ls -la /home/ec2-user/.setup-complete'"
echo ""
echo "📚 For troubleshooting, check the setup log:"
echo "   ssh -i ~/.ssh/$KEY_PAIR_NAME.pem ec2-user@$(terraform output -raw platform_public_ip) 'tail -f /home/ec2-user/setup.log'"
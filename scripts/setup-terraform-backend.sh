#!/bin/bash
# Setup Terraform backend (S3 bucket + DynamoDB table) for shared state

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
AWS_PROFILE="sso-dev-admin"
AWS_REGION="us-east-2"
BUCKET_NAME="golden-path-platform-terraform-state"
TABLE_NAME="golden-path-platform-terraform-locks"

print_status "info" "Setting up Terraform backend for shared state..."

# 1. Create S3 bucket for state
print_status "info" "Creating S3 bucket for Terraform state..."
if aws s3 ls --profile $AWS_PROFILE "s3://$BUCKET_NAME" 2>/dev/null; then
    print_status "warning" "S3 bucket $BUCKET_NAME already exists"
else
    aws s3 mb --profile $AWS_PROFILE "s3://$BUCKET_NAME" --region $AWS_REGION
    print_status "success" "S3 bucket created: $BUCKET_NAME"
fi

# 2. Enable versioning on the bucket
print_status "info" "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning --profile $AWS_PROFILE --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
print_status "success" "Versioning enabled on S3 bucket"

# 3. Enable server-side encryption
print_status "info" "Enabling server-side encryption on S3 bucket..."
aws s3api put-bucket-encryption --profile $AWS_PROFILE --bucket $BUCKET_NAME --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}'
print_status "success" "Server-side encryption enabled on S3 bucket"

# 4. Create DynamoDB table for state locking
print_status "info" "Creating DynamoDB table for state locking..."
if aws dynamodb describe-table --profile $AWS_PROFILE --table-name $TABLE_NAME --region $AWS_REGION >/dev/null 2>&1; then
    print_status "warning" "DynamoDB table $TABLE_NAME already exists"
else
    aws dynamodb create-table --profile $AWS_PROFILE --table-name $TABLE_NAME --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region $AWS_REGION
    print_status "success" "DynamoDB table created: $TABLE_NAME"
    
    # Wait for table to be active
    print_status "info" "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --profile $AWS_PROFILE --table-name $TABLE_NAME --region $AWS_REGION
    print_status "success" "DynamoDB table is now active"
fi

print_status "success" "Terraform backend setup complete!"
echo ""
echo "🎯 Next Steps:"
echo "1. Run: terraform init -migrate-state (to migrate local state to S3)"
echo "2. Run: terraform plan (should show no changes if state is correct)"
echo "3. Commit and push changes to trigger GitHub Actions"
echo "4. GitHub Actions will now use the same shared state"
echo ""
print_status "success" "Shared state backend ready! 🚀"

#!/bin/bash
# Cleanup AWS resources before Terraform deployment
# This script removes existing resources so Terraform can create them fresh

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

print_status "info" "Cleaning up existing AWS resources for fresh Terraform deployment..."

# 1. Terminate EC2 instances
print_status "info" "Terminating EC2 instances..."
INSTANCE_IDS=$(aws ec2 describe-instances --profile $AWS_PROFILE --query 'Reservations[*].Instances[?State.Name==`running` && contains(Tags[?Key==`Name`].Value, `golden-path-platform`)].InstanceId' --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "Found instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --profile $AWS_PROFILE --instance-ids $INSTANCE_IDS
    print_status "info" "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated --profile $AWS_PROFILE --instance-ids $INSTANCE_IDS
    print_status "success" "EC2 instances terminated"
else
    print_status "info" "No running instances found"
fi

# 2. Release Elastic IPs
print_status "info" "Releasing Elastic IPs..."
ALLOCATION_IDS=$(aws ec2 describe-addresses --profile $AWS_PROFILE --query 'Addresses[?InstanceId==null].AllocationId' --output text)

if [ -n "$ALLOCATION_IDS" ]; then
    for allocation_id in $ALLOCATION_IDS; do
        echo "Releasing EIP: $allocation_id"
        aws ec2 release-address --profile $AWS_PROFILE --allocation-id $allocation_id
    done
    print_status "success" "Elastic IPs released"
else
    print_status "info" "No unassociated Elastic IPs found"
fi

# 3. Delete Security Groups
print_status "info" "Deleting Security Groups..."
SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups --profile $AWS_PROFILE --query 'SecurityGroups[?contains(GroupName, `golden-path-platform`)].GroupId' --output text)

if [ -n "$SECURITY_GROUP_IDS" ]; then
    for sg_id in $SECURITY_GROUP_IDS; do
        echo "Deleting Security Group: $sg_id"
        aws ec2 delete-security-group --profile $AWS_PROFILE --group-id $sg_id || print_status "warning" "Failed to delete SG $sg_id (may be in use)"
    done
    print_status "success" "Security Groups deleted"
else
    print_status "info" "No golden-path security groups found"
fi# 4. Delete Platform-specific IAM resources (keep GitHub Actions OIDC role)
print_status "info" "Cleaning up platform-specific IAM resources..."

# Platform-specific resources to clean up
ROLE_NAME="golden-path-platform-instance-role"
POLICY_NAME="golden-path-platform-permissions"
INSTANCE_PROFILE_NAME="golden-path-platform-profile"

# Detach policies from platform role
if aws iam get-role --profile $AWS_PROFILE --role-name $ROLE_NAME >/dev/null 2>&1; then
    print_status "info" "Detaching policy from platform role..."
    aws iam detach-role-policy --profile $AWS_PROFILE --role-name $ROLE_NAME --policy-arn "arn:aws:iam::405474549744:policy/$POLICY_NAME" || true
    
    print_status "info" "Deleting platform IAM role..."
    aws iam delete-role --profile $AWS_PROFILE --role-name $ROLE_NAME || print_status "warning" "Failed to delete platform role"
fi

if aws iam get-policy --profile $AWS_PROFILE --policy-arn "arn:aws:iam::405474549744:policy/$POLICY_NAME" >/dev/null 2>&1; then
    print_status "info" "Deleting platform IAM policy..."
    aws iam delete-policy --profile $AWS_PROFILE --policy-arn "arn:aws:iam::405474549744:policy/$POLICY_NAME" || print_status "warning" "Failed to delete platform policy"
fi

if aws iam get-instance-profile --profile $AWS_PROFILE --instance-profile-name $INSTANCE_PROFILE_NAME >/dev/null 2>&1; then
    print_status "info" "Deleting platform instance profile..."
    aws iam delete-instance-profile --profile $AWS_PROFILE --instance-profile-name $INSTANCE_PROFILE_NAME || print_status "warning" "Failed to delete platform instance profile"
fi

# 5. Keep GitHub Actions OIDC resources (don't delete these)
print_status "info" "Preserving GitHub Actions OIDC resources..."
print_status "success" "✅ Kept: GitHubActions-GoldenPath role (needed for CI/CD)"
print_status "success" "✅ Kept: OIDC Identity Provider (needed for CI/CD)"
print_status "success" "✅ Kept: Other AWS resources (VPCs, etc.)"

print_status "success" "AWS cleanup complete!"
echo ""
echo "🎯 Next Steps:"
echo "1. Run: git add . && git commit -m 'Clean slate for Terraform deployment' && git push origin main"
echo "2. The GitHub Actions workflow will now create everything fresh with Terraform"
echo "3. This demonstrates true GitOps - complete infrastructure as code"
echo ""
print_status "success" "Ready for fresh Terraform deployment! 🚀"

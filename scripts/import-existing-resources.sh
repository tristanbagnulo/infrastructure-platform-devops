#!/bin/bash
# Import existing AWS resources into Terraform state
# This allows Terraform to manage existing infrastructure properly

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

print_status "info" "Importing existing AWS resources into Terraform state..."

cd platform

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    print_status "info" "Initializing Terraform..."
    terraform init
fi

# 1. Import IAM Role
print_status "info" "Importing IAM role..."
if aws iam get-role --profile $AWS_PROFILE --role-name "golden-path-platform-instance-role" >/dev/null 2>&1; then
    terraform import aws_iam_role.platform_instance golden-path-platform-instance-role || print_status "warning" "Role may already be imported"
    print_status "success" "IAM role imported"
else
    print_status "warning" "IAM role not found, will be created"
fi

# 2. Import IAM Policy
print_status "info" "Importing IAM policy..."
POLICY_ARN=$(aws iam list-policies --profile $AWS_PROFILE --query 'Policies[?PolicyName==`golden-path-platform-permissions`].Arn' --output text)
if [ -n "$POLICY_ARN" ]; then
    terraform import aws_iam_policy.platform_permissions $POLICY_ARN || print_status "warning" "Policy may already be imported"
    print_status "success" "IAM policy imported"
else
    print_status "warning" "IAM policy not found, will be created"
fi

# 3. Import IAM Instance Profile
print_status "info" "Importing IAM instance profile..."
if aws iam get-instance-profile --profile $AWS_PROFILE --instance-profile-name "golden-path-platform-profile" >/dev/null 2>&1; then
    terraform import aws_iam_instance_profile.platform golden-path-platform-profile || print_status "warning" "Instance profile may already be imported"
    print_status "success" "IAM instance profile imported"
else
    print_status "warning" "IAM instance profile not found, will be created"
fi

# 4. Import Security Group
print_status "info" "Importing Security Group..."
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --profile $AWS_PROFILE --query 'SecurityGroups[?contains(GroupName, `golden-path-platform`) && contains(GroupName, `20250904`)].GroupId' --output text | head -1)
if [ -n "$SECURITY_GROUP_ID" ]; then
    terraform import aws_security_group.platform $SECURITY_GROUP_ID || print_status "warning" "Security group may already be imported"
    print_status "success" "Security group imported: $SECURITY_GROUP_ID"
else
    print_status "warning" "Security group not found, will be created"
fi

# 5. Import Elastic IP
print_status "info" "Importing Elastic IP..."
ALLOCATION_ID=$(aws ec2 describe-addresses --profile $AWS_PROFILE --query 'Addresses[?PublicIp==`18.223.242.198`].AllocationId' --output text)
if [ -n "$ALLOCATION_ID" ]; then
    terraform import aws_eip.platform $ALLOCATION_ID || print_status "warning" "Elastic IP may already be imported"
    print_status "success" "Elastic IP imported: $ALLOCATION_ID"
else
    print_status "warning" "Elastic IP not found, will be created"
fi

# 6. Import EC2 Instance
print_status "info" "Importing EC2 instance..."
INSTANCE_ID=$(aws ec2 describe-instances --profile $AWS_PROFILE --query 'Reservations[*].Instances[?State.Name==`running` && PublicIpAddress==`18.223.242.198`].InstanceId' --output text)
if [ -n "$INSTANCE_ID" ]; then
    terraform import aws_instance.platform $INSTANCE_ID || print_status "warning" "EC2 instance may already be imported"
    print_status "success" "EC2 instance imported: $INSTANCE_ID"
else
    print_status "warning" "EC2 instance not found, will be created"
fi

# 7. Import EIP Association
print_status "info" "Importing EIP association..."
if [ -n "$INSTANCE_ID" ] && [ -n "$ALLOCATION_ID" ]; then
    terraform import aws_eip_association.platform $ALLOCATION_ID || print_status "warning" "EIP association may already be imported"
    print_status "success" "EIP association imported"
else
    print_status "warning" "EIP association not found, will be created"
fi

print_status "success" "Import process complete!"
echo ""
echo "🎯 Next Steps:"
echo "1. Run: terraform plan (should show no changes if everything is imported correctly)"
echo "2. Run: terraform apply (should make no changes if state matches reality)"
echo "3. Commit and push changes to trigger GitHub Actions"
echo "4. GitHub Actions should now work with existing infrastructure"
echo ""
print_status "success" "Terraform now manages existing infrastructure! 🚀"

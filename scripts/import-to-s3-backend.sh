#!/bin/bash
# Import existing AWS resources into S3 backend state

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

print_status "info" "Importing existing resources into S3 backend..."

cd platform

# Initialize with S3 backend
print_status "info" "Initializing S3 backend..."
terraform init

# Import existing resources
print_status "info" "Importing IAM role..."
terraform import aws_iam_role.platform_instance golden-path-platform-instance-role || print_status "warning" "Role may already be imported"

print_status "info" "Importing IAM policy..."
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName==\`golden-path-platform-permissions\`].Arn" --output text)
if [ -n "$POLICY_ARN" ]; then
    terraform import aws_iam_policy.platform_permissions "$POLICY_ARN" || print_status "warning" "Policy may already be imported"
fi

print_status "info" "Importing IAM instance profile..."
terraform import aws_iam_instance_profile.platform golden-path-platform-profile || print_status "warning" "Instance profile may already be imported"

print_status "info" "Importing Security Group..."
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, \`golden-path-platform\`)].GroupId" --output text | head -1)
if [ -n "$SECURITY_GROUP_ID" ]; then
    terraform import aws_security_group.platform "$SECURITY_GROUP_ID" || print_status "warning" "Security group may already be imported"
fi

print_status "info" "Importing Elastic IP..."
ALLOCATION_ID=$(aws ec2 describe-addresses --query "Addresses[?PublicIp==\`18.223.242.198\`].AllocationId" --output text)
if [ -n "$ALLOCATION_ID" ]; then
    terraform import aws_eip.platform "$ALLOCATION_ID" || print_status "warning" "Elastic IP may already be imported"
fi

print_status "info" "Importing EC2 instance..."
INSTANCE_ID=$(aws ec2 describe-instances --query "Reservations[*].Instances[?State.Name==\`running\` && PublicIpAddress==\`18.223.242.198\`].InstanceId" --output text)
if [ -n "$INSTANCE_ID" ]; then
    terraform import aws_instance.platform "$INSTANCE_ID" || print_status "warning" "EC2 instance may already be imported"
fi

if [ -n "$INSTANCE_ID" ] && [ -n "$ALLOCATION_ID" ]; then
    terraform import aws_eip_association.platform "$ALLOCATION_ID" || print_status "warning" "EIP association may already be imported"
fi

print_status "success" "Import complete! S3 backend now has existing resources."
echo ""
echo "🎯 Next: Run 'terraform plan' to verify no changes needed"

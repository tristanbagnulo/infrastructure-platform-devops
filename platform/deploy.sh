#!/bin/bash
set -e

# Golden Path Platform Deployment Script
# Deploys the platform with full multi-account governance

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required tools
    local required_tools=("terraform" "aws" "ssh-keygen" "jq")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done
    
    # Check AWS configuration
    if [[ ! -f ~/.aws/config ]]; then
        log_error "AWS configuration not found. Please configure AWS SSO."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Setup AWS credentials for deployment
setup_aws_credentials() {
    local environment=$1
    log_info "Setting up AWS credentials for $environment..."
    
    # Map environment to profile
    case $environment in
        dev)
            AWS_PROFILE="sso-dev"
            ;;
        stage)
            AWS_PROFILE="sso-stage"
            ;;
        prod)
            AWS_PROFILE="sso-prod"
            ;;
        *)
            log_error "Invalid environment: $environment"
            exit 1
            ;;
    esac
    
    # Check if logged in to SSO
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        log_warning "AWS SSO session expired. Please log in..."
        aws sso login --profile "$AWS_PROFILE"
    fi
    
    # Verify account
    local account_id=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text)
    log_success "Connected to AWS account: $account_id"
    
    export AWS_PROFILE
}

# Create SSH key pair if it doesn't exist
setup_ssh_key() {
    local environment=$1
    local key_name="golden-path-$environment"
    local key_path="$HOME/.ssh/$key_name"
    
    log_info "Setting up SSH key for $environment..."
    
    if [[ ! -f "$key_path" ]]; then
        log_info "Creating SSH key pair: $key_name"
        ssh-keygen -t rsa -b 4096 -f "$key_path" -N "" -C "golden-path-$environment"
        
        # Import to AWS
        aws ec2 import-key-pair \
            --key-name "$key_name" \
            --public-key-material "fileb://$key_path.pub" \
            --profile "$AWS_PROFILE"
        
        log_success "SSH key created and imported to AWS"
    else
        log_info "SSH key already exists: $key_path"
    fi
}

# Setup Terraform backend
setup_terraform_backend() {
    local environment=$1
    local account_id=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text)
    local bucket_name="golden-path-terraform-state-$account_id"
    
    log_info "Setting up Terraform backend..."
    
    # Create S3 bucket for Terraform state
    if ! aws s3 ls "s3://$bucket_name" --profile "$AWS_PROFILE" &> /dev/null; then
        log_info "Creating Terraform state bucket: $bucket_name"
        aws s3 mb "s3://$bucket_name" --profile "$AWS_PROFILE" --region us-east-2
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$bucket_name" \
            --versioning-configuration Status=Enabled \
            --profile "$AWS_PROFILE"
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$bucket_name" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }' \
            --profile "$AWS_PROFILE"
        
        log_success "Terraform state bucket created"
    else
        log_info "Terraform state bucket already exists"
    fi
}

# Deploy permission boundaries
deploy_permission_boundaries() {
    local environment=$1
    log_info "Deploying permission boundaries for $environment..."
    
    cd "$SCRIPT_DIR/../governance"
    
    terraform init
    terraform plan -var="app_name=*" -out=boundaries.tfplan
    terraform apply -auto-approve boundaries.tfplan
    
    log_success "Permission boundaries deployed"
    cd "$SCRIPT_DIR"
}

# Deploy platform infrastructure
deploy_platform() {
    local environment=$1
    log_info "Deploying Golden Path Platform for $environment..."
    
    cd "$SCRIPT_DIR"
    
    # Initialize Terraform
    terraform init \
        -backend-config="bucket=golden-path-terraform-state-$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text)" \
        -backend-config="key=platform/$environment/terraform.tfstate" \
        -backend-config="region=us-east-2" \
        -backend-config="profile=$AWS_PROFILE"
    
    # Plan deployment
    terraform plan \
        -var="aws_region=us-east-2" \
        -var="environment=$environment" \
        -var="key_pair_name=golden-path-$environment" \
        -out=platform.tfplan
    
    # Apply deployment
    log_info "Applying Terraform plan..."
    terraform apply -auto-approve platform.tfplan
    
    # Get platform IP
    PLATFORM_IP=$(terraform output -raw platform_public_ip)
    log_success "Platform deployed at: $PLATFORM_IP"
    
    # Save platform info
    cat > platform-info.json << EOF
{
    "environment": "$environment",
    "platform_ip": "$PLATFORM_IP",
    "ssh_command": "ssh -i ~/.ssh/golden-path-$environment.pem ubuntu@$PLATFORM_IP",
    "jenkins_url": "http://$PLATFORM_IP:8080",
    "kubernetes_url": "https://$PLATFORM_IP:6443"
}
EOF
    
    log_success "Platform information saved to platform-info.json"
}

# Wait for platform to be ready
wait_for_platform() {
    local environment=$1
    local platform_ip=$2
    local max_attempts=30
    local attempt=0
    
    log_info "Waiting for platform to be ready..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        if ssh -i ~/.ssh/golden-path-$environment.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$platform_ip "echo 'Platform ready'" &> /dev/null; then
            log_success "Platform is ready!"
            return 0
        fi
        
        log_info "Attempt $((attempt + 1))/$max_attempts - Platform not ready yet..."
        sleep 30
        ((attempt++))
    done
    
    log_error "Platform failed to become ready within timeout"
    exit 1
}

# Setup platform components
setup_platform_components() {
    local environment=$1
    local platform_ip=$2
    
    log_info "Setting up platform components..."
    
    # Copy configuration files
    scp -i ~/.ssh/golden-path-$environment.pem -o StrictHostKeyChecking=no \
        jenkins-config/casc.yaml \
        ubuntu@$platform_ip:/home/ubuntu/jenkins-casc.yaml
    
    # Run platform setup
    ssh -i ~/.ssh/golden-path-$environment.pem -o StrictHostKeyChecking=no ubuntu@$platform_ip << 'EOF'
        # Wait for user-data to complete
        cloud-init status --wait
        
        # Run platform setup
        ./setup-platform.sh
        
        # Configure Jenkins with CasC
        kubectl create configmap jenkins-casc --from-file=/home/ubuntu/jenkins-casc.yaml -n jenkins
        kubectl patch deployment jenkins -n jenkins -p '{"spec":{"template":{"spec":{"containers":[{"name":"jenkins","env":[{"name":"CASC_JENKINS_CONFIG","value":"/var/jenkins_home/casc_configs/jenkins-casc.yaml"}],"volumeMounts":[{"name":"casc-config","mountPath":"/var/jenkins_home/casc_configs"}]}],"volumes":[{"name":"casc-config","configMap":{"name":"jenkins-casc"}}]}}}}'
        
        # Wait for Jenkins to be ready
        kubectl wait --namespace jenkins --for=condition=ready pod --selector=app=jenkins --timeout=300s
        
        echo "✅ Platform components setup complete"
EOF
    
    log_success "Platform components configured"
}

# Run integration tests
run_integration_tests() {
    local environment=$1
    local platform_ip=$2
    
    log_info "Running integration tests..."
    
    ssh -i ~/.ssh/golden-path-$environment.pem -o StrictHostKeyChecking=no ubuntu@$platform_ip << EOF
        cd /home/ubuntu/workspace/infrastructure-platform-devops/runner
        
        # Test infrastructure generation
        python3 scripts/render.py \\
            ../../examples/photo-service/infra/requests/dev.yaml \\
            \$(aws sts get-caller-identity --query Account --output text) \\
            us-east-2 \\
            "arn:aws:iam::\$(aws sts get-caller-identity --query Account --output text):oidc-provider/example" \\
            example \\
            integration-test.tf.json
        
        echo "✅ Integration tests passed"
EOF
    
    log_success "Integration tests completed"
}

# Main deployment function
main() {
    local environment=${1:-dev}
    
    echo "🚀 Golden Path Platform Deployment"
    echo "Environment: $environment"
    echo "=================================="
    
    check_prerequisites
    setup_aws_credentials "$environment"
    setup_ssh_key "$environment"
    setup_terraform_backend "$environment"
    deploy_permission_boundaries "$environment"
    deploy_platform "$environment"
    
    # Get platform IP from Terraform output
    PLATFORM_IP=$(terraform output -raw platform_public_ip)
    
    wait_for_platform "$environment" "$PLATFORM_IP"
    setup_platform_components "$environment" "$PLATFORM_IP"
    run_integration_tests "$environment" "$PLATFORM_IP"
    
    echo ""
    echo "🎉 Golden Path Platform deployed successfully!"
    echo ""
    echo "📋 Platform Access:"
    echo "   SSH: ssh -i ~/.ssh/golden-path-$environment.pem ubuntu@$PLATFORM_IP"
    echo "   Jenkins: http://$PLATFORM_IP:8080"
    echo "   Kubernetes: https://$PLATFORM_IP:6443"
    echo ""
    echo "📝 Next Steps:"
    echo "   1. Configure Jenkins with your Git repositories"
    echo "   2. Test application deployments"
    echo "   3. Set up monitoring and alerting"
    echo ""
}

# Handle script arguments
case "${1:-help}" in
    dev|stage|prod)
        main "$1"
        ;;
    destroy)
        environment=${2:-dev}
        log_warning "Destroying platform for $environment..."
        setup_aws_credentials "$environment"
        cd "$SCRIPT_DIR"
        terraform destroy -auto-approve \
            -var="aws_region=us-east-2" \
            -var="environment=$environment" \
            -var="key_pair_name=golden-path-$environment"
        log_success "Platform destroyed"
        ;;
    help|*)
        echo "Golden Path Platform Deployment"
        echo ""
        echo "Usage:"
        echo "  $0 <environment>     Deploy platform to environment"
        echo "  $0 destroy <env>     Destroy platform in environment"
        echo ""
        echo "Environments: dev, stage, prod"
        echo ""
        echo "Examples:"
        echo "  $0 dev              # Deploy to dev account"
        echo "  $0 stage            # Deploy to stage account"  
        echo "  $0 destroy dev      # Destroy dev platform"
        echo ""
        echo "💡 Cost-Optimized for Demos:"
        echo "  • Only deploy when needed for testing/demos"
        echo "  • Destroy after use: ./deploy.sh destroy <env>"
        echo "  • 20GB storage (minimal for demos): +$0.003/hour"
        echo "  • Dev environment: ~$0.045/hour (~$0.09 for 2-hour demo)"
        echo "  • All environments: ~$0.30/hour (~$2.40 for 8-hour demo)"
        ;;
esac

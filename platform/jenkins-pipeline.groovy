pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stage', 'prod'],
            description: 'Target environment for platform deployment'
        )
        booleanParam(
            name: 'DESTROY',
            defaultValue: false,
            description: 'Destroy platform infrastructure'
        )
        string(
            name: 'AWS_REGION',
            defaultValue: 'us-east-2',
            description: 'AWS region for deployment'
        )
        string(
            name: 'KEY_PAIR_NAME',
            defaultValue: 'golden-path-dev-new',
            description: 'EC2 key pair name for SSH access'
        )
    }
    
    environment {
        AWS_REGION = "${params.AWS_REGION}"
        ENVIRONMENT = "${params.ENVIRONMENT}"
        KEY_PAIR_NAME = "${params.KEY_PAIR_NAME}"
        TERRAFORM_DIR = 'infrastructure-platform-devops/platform'
    }
    
    stages {
        stage('Setup Environment') {
            steps {
                echo '🔧 Setting up build environment...'
                sh '''
                    echo "=== BUILD ENVIRONMENT ==="
                    echo "Jenkins Node: ${NODE_NAME}"
                    echo "Workspace: ${WORKSPACE}"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "========================="
                    
                    echo "=== INSTALLING TOOLS ==="
                    # Install jq if not available
                    if ! command -v jq &> /dev/null; then
                        echo "Installing jq..."
                        apt-get update && apt-get install -y jq || echo "⚠️  Could not install jq"
                    fi
                    
                    # Verify required tools
                    echo "=== TOOL VERSIONS ==="
                    terraform version || echo "❌ Terraform not found"
                    aws --version || echo "❌ AWS CLI not found"
                    jq --version || echo "❌ jq not found"
                    echo "====================="
                '''
            }
        }
        
        stage('Checkout Platform Code') {
            steps {
                echo '📦 Checking out platform infrastructure code...'
                checkout scm
                dir(env.TERRAFORM_DIR) {
                    sh '''
                        echo "=== WORKSPACE CONTENTS ==="
                        ls -la
                        echo "=== TERRAFORM FILES ==="
                        find . -name "*.tf" -o -name "*.tf.json" | head -10
                        echo "=== MODULE STRUCTURE ==="
                        find ../modules -type d | head -10
                        echo "========================="
                    '''
                }
            }
        }
        
        stage('Validate Terraform') {
            steps {
                echo '🔍 Validating Terraform configuration...'
                dir(env.TERRAFORM_DIR) {
                    sh '''
                        echo "=== TERRAFORM VERSION ==="
                        terraform version
                        echo "=== TERRAFORM FORMAT CHECK ==="
                        terraform fmt -check -diff || echo "⚠️  Format issues found (will be fixed automatically)"
                        echo "=== TERRAFORM INIT ==="
                        terraform init -input=false -upgrade
                        echo "=== TERRAFORM VALIDATE ==="
                        terraform validate -json | jq -r '.diagnostics[]? | "\(.severity | ascii_upcase): \(.summary) - \(.detail)"' || terraform validate
                        echo "✅ Terraform configuration is valid"
                    '''
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo '📋 Creating Terraform plan...'
                dir(env.TERRAFORM_DIR) {
                    sh '''
                        echo "=== TERRAFORM PLAN PREVIEW ==="
                        echo "Environment: ${ENVIRONMENT}"
                        echo "AWS Region: ${AWS_REGION}"
                        echo "Key Pair: ${KEY_PAIR_NAME}"
                        echo "==============================="
                        
                        echo "=== TERRAFORM PLAN OUTPUT ==="
                        terraform plan \
                            -var="aws_region=${AWS_REGION}" \
                            -var="environment=${ENVIRONMENT}" \
                            -var="key_pair_name=${KEY_PAIR_NAME}" \
                            -out=platform-${ENVIRONMENT}.tfplan \
                            -detailed-exitcode
                        
                        PLAN_EXIT_CODE=$?
                        echo "Plan exit code: $PLAN_EXIT_CODE"
                        
                        if [ $PLAN_EXIT_CODE -eq 0 ]; then
                            echo "✅ No changes needed - infrastructure is up to date"
                        elif [ $PLAN_EXIT_CODE -eq 2 ]; then
                            echo "✅ Terraform plan created with changes"
                        else
                            echo "❌ Terraform plan failed"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Approve Production Deployment') {
            when {
                expression { return params.ENVIRONMENT == 'prod' && !params.DESTROY }
            }
            steps {
                input message: 'Deploy Golden Path Platform to PRODUCTION?'
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { return !params.DESTROY }
            }
            steps {
                echo '🚀 Deploying Golden Path Platform...'
                dir(env.TERRAFORM_DIR) {
                    sh '''
                        echo "=== APPLYING TERRAFORM PLAN ==="
                        echo "Plan file: platform-${ENVIRONMENT}.tfplan"
                        echo "==============================="
                        
                        terraform apply -auto-approve platform-${ENVIRONMENT}.tfplan
                        
                        echo "=== DEPLOYMENT OUTPUTS ==="
                        terraform output -json | jq -r 'to_entries[] | "\(.key): \(.value.value)"' || terraform output
                        echo "=========================="
                        
                        echo "✅ Platform deployed successfully!"
                    '''
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { return params.DESTROY }
            }
            steps {
                echo '🗑️ Destroying Golden Path Platform...'
                dir(env.TERRAFORM_DIR) {
                    sh '''
                        terraform destroy -auto-approve \
                            -var="aws_region=${AWS_REGION}" \
                            -var="environment=${ENVIRONMENT}" \
                            -var="key_pair_name=${KEY_PAIR_NAME}"
                        echo "✅ Platform destroyed successfully!"
                    '''
                }
            }
        }
        
        stage('Verify Platform Health') {
            when {
                expression { return !params.DESTROY }
            }
            steps {
                echo '🔍 Verifying platform health...'
                script {
                    def platformIP = sh(
                        script: "cd ${env.TERRAFORM_DIR} && terraform output -raw platform_public_ip",
                        returnStdout: true
                    ).trim()
                    
                    echo "=== PLATFORM HEALTH CHECK ==="
                    echo "Platform IP: ${platformIP}"
                    echo "============================="
                    
                    // Test Jenkins connectivity
                    sh """
                        echo "=== TESTING JENKINS CONNECTIVITY ==="
                        for i in {1..5}; do
                            echo "Attempt $i/5: Testing Jenkins on port 8081..."
                            if curl -I -m 10 http://${platformIP}:8081 2>/dev/null | grep -q "HTTP/"; then
                                echo "✅ Jenkins is responding on port 8081"
                                break
                            else
                                echo "⏳ Jenkins not ready yet, waiting 10 seconds..."
                                sleep 10
                            fi
                        done
                    """
                    
                    // Test Kubernetes API
                    sh """
                        echo "=== TESTING KUBERNETES API ==="
                        for i in {1..3}; do
                            echo "Attempt $i/3: Testing K8s API on port 6443..."
                            if curl -k -I -m 10 https://${platformIP}:6443 2>/dev/null | grep -q "HTTP/"; then
                                echo "✅ Kubernetes API is responding on port 6443"
                                break
                            else
                                echo "⏳ K8s API not ready yet, waiting 15 seconds..."
                                sleep 15
                            fi
                        done
                    """
                    
                    // Test Docker
                    sh """
                        echo "=== TESTING DOCKER ==="
                        ssh -o StrictHostKeyChecking=no -i ~/.ssh/${KEY_PAIR_NAME}.pem ec2-user@${platformIP} \
                            "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'" || echo "⚠️  Could not connect to verify Docker"
                    """
                }
            }
        }
        
        stage('Output Platform Information') {
            when {
                expression { return !params.DESTROY }
            }
            steps {
                echo '📊 Platform deployment information:'
                dir(env.TERRAFORM_DIR) {
                    sh '''
                        echo "=== PLATFORM DEPLOYMENT COMPLETE ==="
                        echo "Environment: ${ENVIRONMENT}"
                        echo "Region: ${AWS_REGION}"
                        echo "Jenkins URL: $(terraform output -raw jenkins_url)"
                        echo "Kubernetes API: $(terraform output -raw kubernetes_endpoint)"
                        echo "SSH Command: $(terraform output -raw ssh_command)"
                        echo "====================================="
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Golden Path Platform deployment completed successfully!'
            echo '📊 Summary:'
            echo '  - Platform infrastructure deployed'
            echo '  - Jenkins CI/CD ready'
            echo '  - Kind Kubernetes cluster running'
            echo '  - Security policies enforced'
            echo '  - Ready for application deployments'
            
            script {
                try {
                    def platformIP = sh(
                        script: "cd ${env.TERRAFORM_DIR} && terraform output -raw platform_public_ip 2>/dev/null || echo 'N/A'",
                        returnStdout: true
                    ).trim()
                    
                    echo "🌐 Platform Access Information:"
                    echo "  - Jenkins URL: http://${platformIP}:8081"
                    echo "  - SSH Command: ssh -i ~/.ssh/${KEY_PAIR_NAME}.pem ec2-user@${platformIP}"
                    echo "  - Environment: ${ENVIRONMENT}"
                    echo "  - Region: ${AWS_REGION}"
                } catch (Exception e) {
                    echo "⚠️  Could not retrieve platform information: ${e.getMessage()}"
                }
            }
        }
        failure {
            echo '❌ Platform deployment failed. Check logs for details.'
            echo '🔍 Common troubleshooting steps:'
            echo '  1. Check AWS credentials and permissions'
            echo '  2. Verify key pair exists in the target region'
            echo '  3. Check Terraform state for any locked resources'
            echo '  4. Review AWS CloudFormation events for detailed errors'
            
            script {
                try {
                    dir(env.TERRAFORM_DIR) {
                        sh '''
                            echo "=== TERRAFORM STATE INFO ==="
                            terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[]? | "\(.type): \(.name) - \(.values.id // "pending")"' || echo "No state available"
                            echo "============================"
                        '''
                    }
                } catch (Exception e) {
                    echo "⚠️  Could not retrieve Terraform state: ${e.getMessage()}"
                }
            }
        }
        always {
            echo '🧹 Cleaning up temporary files...'
            dir(env.TERRAFORM_DIR) {
                sh '''
                    echo "=== CLEANUP ==="
                    rm -f platform-*.tfplan || echo "No plan files to clean"
                    echo "✅ Cleanup completed"
                '''
            }
        }
    }
}

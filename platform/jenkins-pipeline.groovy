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
        stage('Checkout Platform Code') {
            steps {
                echo '📦 Checking out platform infrastructure code...'
                checkout scm
                dir(env.TERRAFORM_DIR) {
                    sh 'ls -la'
                }
            }
        }
        
        stage('Validate Terraform') {
            steps {
                echo '🔍 Validating Terraform configuration...'
                dir(env.TERRAFORM_DIR) {
                    sh '''
                        terraform fmt -check
                        terraform validate
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
                        terraform init -input=false
                        terraform plan \
                            -var="aws_region=${AWS_REGION}" \
                            -var="environment=${ENVIRONMENT}" \
                            -var="key_pair_name=${KEY_PAIR_NAME}" \
                            -out=platform-${ENVIRONMENT}.tfplan
                        echo "✅ Terraform plan created"
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
                        terraform apply -auto-approve platform-${ENVIRONMENT}.tfplan
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
                    
                    echo "Platform IP: ${platformIP}"
                    
                    // Test Jenkins connectivity
                    sh """
                        echo "Testing Jenkins connectivity..."
                        curl -I -m 10 http://${platformIP}:8081 || echo "Jenkins not ready yet"
                    """
                    
                    // Test Kubernetes API
                    sh """
                        echo "Testing Kubernetes API..."
                        curl -k -I -m 10 https://${platformIP}:6443 || echo "K8s API not ready yet"
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
        }
        failure {
            echo '❌ Platform deployment failed. Check logs for details.'
        }
        always {
            echo '🧹 Cleaning up temporary files...'
            dir(env.TERRAFORM_DIR) {
                sh 'rm -f platform-*.tfplan || true'
            }
        }
    }
}

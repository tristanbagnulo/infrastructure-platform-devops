#!/bin/bash
# Quick Jenkins GitHub Integration Setup for Interview Demo
# This script sets up the essential Jenkins GitHub connection for demonstration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JENKINS_URL="http://18.223.242.198:8081"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"  # Default password, change if needed
GITHUB_REPO="https://github.com/tristanbagnulo/infrastructure-platform-devops.git"

# Helper function for colored output
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

# Check if Jenkins is accessible
check_jenkins() {
    print_status "info" "Checking Jenkins accessibility..."
    if curl -s "$JENKINS_URL" > /dev/null; then
        print_status "success" "Jenkins is accessible at $JENKINS_URL"
    else
        print_status "error" "Jenkins is not accessible at $JENKINS_URL"
        exit 1
    fi
}

# Get Jenkins CSRF token
get_crumb() {
    print_status "info" "Getting Jenkins CSRF token..."
    CRUMB=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
    CRUMB_FIELD=$(echo "$CRUMB" | cut -d: -f1)
    CRUMB_VALUE=$(echo "$CRUMB" | cut -d: -f2)
    
    if [ -z "$CRUMB_VALUE" ]; then
        print_status "error" "Failed to get CSRF token"
        exit 1
    fi
    
    print_status "success" "CSRF token obtained"
}

# Create Jenkins Pipeline Job
create_pipeline_job() {
    print_status "info" "Creating Jenkins Pipeline job..."
    
    # Create pipeline configuration
    cat > pipeline-config.xml << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.47">
  <description>Golden Path Infrastructure Platform Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.ChoiceParameterDefinition>
          <name>ENVIRONMENT</name>
          <description>Target environment for platform deployment</description>
          <choices class="java.util.Arrays\$ArrayList">
            <a class="string-array">
              <string>dev</string>
              <string>stage</string>
              <string>prod</string>
            </a>
          </choices>
        </hudson.model.ChoiceParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>DESTROY</name>
          <description>Destroy platform infrastructure</description>
          <defaultValue>false</defaultValue>
        </hudson.model.BooleanParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>AWS_REGION</name>
          <description>AWS region for deployment</description>
          <defaultValue>us-east-2</defaultValue>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>KEY_PAIR_NAME</name>
          <description>EC2 key pair name for SSH access</description>
          <defaultValue>golden-path-dev-new</defaultValue>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.93">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.11.3">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>$GITHUB_REPO</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>false</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

    # Create the Pipeline job
    if curl -X POST \
      -H "$CRUMB_FIELD: $CRUMB_VALUE" \
      -H "Content-Type: application/xml" \
      -d @pipeline-config.xml \
      "$JENKINS_URL/createItem?name=golden-path-infrastructure-pipeline"; then
        print_status "success" "Pipeline job created successfully!"
    else
        print_status "error" "Failed to create pipeline job"
        exit 1
    fi
}

# Test the pipeline
test_pipeline() {
    print_status "info" "Testing pipeline job..."
    
    # Trigger a build
    if curl -X POST \
      -H "$CRUMB_FIELD: $CRUMB_VALUE" \
      "$JENKINS_URL/job/golden-path-infrastructure-pipeline/build"; then
        print_status "success" "Pipeline build triggered!"
        echo "Check the build status at: $JENKINS_URL/job/golden-path-infrastructure-pipeline/"
    else
        print_status "error" "Failed to trigger pipeline build"
        exit 1
    fi
}

# Main execution
main() {
    print_status "info" "Setting up Jenkins GitHub integration for interview demo..."
    
    check_jenkins
    get_crumb
    create_pipeline_job
    test_pipeline
    
    print_status "success" "Jenkins GitHub integration setup complete!"
    echo ""
    echo "🎯 Demo Ready:"
    echo "  - Jenkins URL: $JENKINS_URL"
    echo "  - Pipeline Job: golden-path-infrastructure-pipeline"
    echo "  - GitHub Repo: $GITHUB_REPO"
    echo "  - Auto-trigger: Every 5 minutes on main branch"
    echo ""
    echo "📋 For your interview demo:"
    echo "  1. Show Jenkins dashboard: $JENKINS_URL"
    echo "  2. Show pipeline job configuration"
    echo "  3. Trigger a manual build"
    echo "  4. Show build logs and progress"
    echo "  5. Show GitHub integration"
}

# Run main function
main "$@"

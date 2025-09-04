#!/bin/bash

# Setup Jenkins Pipeline as Code
# This script configures Jenkins to use our Jenkinsfile from the repository

set -e

JENKINS_URL="http://3.14.250.17:8081"
REPO_URL="https://github.com/tristanbagnulo/infrastructure-platform-devops.git"
BRANCH="main"
JENKINSFILE_PATH="Jenkinsfile"

echo "🚀 Setting up Jenkins Pipeline as Code..."

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be ready..."
sleep 10

# Get CSRF token
echo "🔑 Getting CSRF token..."
CRUMB=$(curl -s "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumb')
CRUMB_FIELD=$(curl -s "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumbRequestField')

echo "📋 CSRF Token: $CRUMB"

# Create Pipeline job configuration
echo "📝 Creating Pipeline job configuration..."
cat > pipeline-config.xml << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.50">
  <description>Infrastructure Platform DevOps Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.plugins.discard__build.DiscardBuildProperty>
      <strategy class="hudson.plugins.discard__build.DiscardOldBuildStrategy">
        <daysToKeepStr>10</daysToKeepStr>
        <numToKeepStr>5</numToKeepStr>
        <artifactDaysToKeepStr>-1</artifactDaysToKeepStr>
        <artifactNumToKeepStr>-1</artifactNumToKeepStr>
      </strategy>
    </hudson.plugins.discard__build.DiscardBuildProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.95">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.15.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>$REPO_URL</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/$BRANCH</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>$JENKINSFILE_PATH</scriptPath>
    <lightweight>false</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Create the Pipeline job
echo "🔧 Creating Pipeline job..."
curl -X POST \
  -H "$CRUMB_FIELD: $CRUMB" \
  -H "Content-Type: application/xml" \
  -d @pipeline-config.xml \
  "$JENKINS_URL/createItem?name=infrastructure-platform-pipeline"

if [ $? -eq 0 ]; then
    echo "✅ Pipeline job created successfully!"
    echo "🌐 Access Jenkins at: $JENKINS_URL"
    echo "📋 Pipeline job: infrastructure-platform-pipeline"
    echo "🔄 Jenkins will automatically use the Jenkinsfile from the repository"
else
    echo "❌ Failed to create Pipeline job"
    exit 1
fi

# Clean up
rm -f pipeline-config.xml

echo "🎉 Jenkins Pipeline as Code setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open Jenkins: $JENKINS_URL"
echo "2. Go to 'infrastructure-platform-pipeline' job"
echo "3. Click 'Build with Parameters' to run the pipeline"
echo "4. Any changes to Jenkinsfile in the repo will be automatically reflected"

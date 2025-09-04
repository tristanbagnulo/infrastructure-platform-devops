#!/bin/bash
# Jenkins GitOps Plugin Installation Script
# This script pre-installs all necessary plugins for Jenkins GitOps integration
# Includes: Pipeline, Git, GitHub, Kubernetes, Docker, and utility plugins

set -e

echo "🔌 Installing Jenkins GitOps plugins..."

# List of essential Pipeline and GitOps plugins
PLUGINS=(
    # Core Pipeline plugins
    "workflow-job"
    "workflow-cps"
    "workflow-cps-global-lib"
    "workflow-basic-steps"
    "workflow-durable-task-step"
    "workflow-step-api"
    "workflow-api"
    "workflow-support"
    "workflow-scm-step"
    "workflow-multibranch"
    "workflow-stage-step"
    "workflow-input-step"
    "workflow-milestone-step"
    "workflow-build-step"
    "workflow-groovy-lib"
    "workflow-github"
    "workflow-github-lib"
    "workflow-stage-tags-metadata"
    "workflow-model-api"
    "workflow-declarative-agent-api"
    "workflow-declarative-extension-points-api"
    "workflow-aggregator"
    "pipeline-stage-view"
    "pipeline-graph-analysis"
    "pipeline-rest-api"
    "pipeline-utility-steps"
    "pipeline-maven"
    "pipeline-github-lib"
    "pipeline-github"
    "pipeline-multibranch"
    "pipeline-stage-tags-metadata"
    "pipeline-model-api"
    "pipeline-declarative-agent-api"
    "pipeline-declarative-extension-points-api"
    "pipeline-cps-global-lib"
    "pipeline-aggregator"
    
    # GitOps and Git Integration plugins
    "git"
    "git-client"
    "scm-api"
    "credentials-binding"
    "docker-workflow"
    "kubernetes"
    "github"
    "github-branch-source"
    "github-pullrequest"
    "github-organization-folder"
    
    # Additional useful plugins
    "blueocean"
    "configuration-as-code"
    "job-dsl"
    "build-timeout"
    "timestamper"
    "ws-cleanup"
    "ant"
    "gradle"
    "workflow-aggregator"
    "pipeline-github-lib"
    "pipeline-stage-view"
    "pipeline-utility-steps"
    "pipeline-maven"
    "pipeline-github"
    "pipeline-multibranch"
    "pipeline-stage-tags-metadata"
    "pipeline-model-api"
    "pipeline-declarative-agent-api"
    "pipeline-declarative-extension-points-api"
    "pipeline-cps-global-lib"
    "pipeline-aggregator"
)

# Function to install a plugin
install_plugin() {
    local plugin_name=$1
    local plugin_file="/var/jenkins_home/plugins/${plugin_name}.jpi"
    local plugin_url="https://updates.jenkins.io/latest/${plugin_name}.hpi"
    
    echo "Installing ${plugin_name}..."
    if curl -L -o "${plugin_file}" "${plugin_url}"; then
        echo "✅ ${plugin_name} installed successfully"
    else
        echo "❌ Failed to install ${plugin_name}"
        return 1
    fi
}

# Install all plugins
for plugin in "${PLUGINS[@]}"; do
    install_plugin "${plugin}" || echo "⚠️  Warning: Failed to install ${plugin}"
done

echo "🎉 Plugin installation complete!"
echo "📋 Installed plugins:"
find /var/jenkins_home/plugins -name "*.jpi" | wc -l | xargs echo "Total plugins:"

echo "🔄 Restarting Jenkins to load plugins..."
# Note: This script should be run inside the Jenkins container
# The restart will be handled by the calling script

#!/bin/bash
# Jenkins Plugin Installation and Port Forwarding Script
set -e

echo "🔌 Installing Jenkins plugins..."

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins

# Install essential plugins
kubectl exec -n jenkins deployment/jenkins -- bash -c '
    echo "Installing Jenkins plugins..."
    curl -L -o /var/jenkins_home/plugins/git.hpi https://updates.jenkins.io/latest/git.hpi
    curl -L -o /var/jenkins_home/plugins/workflow-aggregator.hpi https://updates.jenkins.io/latest/workflow-aggregator.hpi
    curl -L -o /var/jenkins_home/plugins/pipeline-stage-view.hpi https://updates.jenkins.io/latest/pipeline-stage-view.hpi
    curl -L -o /var/jenkins_home/plugins/github.hpi https://updates.jenkins.io/latest/github.hpi
    curl -L -o /var/jenkins_home/plugins/kubernetes.hpi https://updates.jenkins.io/latest/kubernetes.hpi
    curl -L -o /var/jenkins_home/plugins/docker-workflow.hpi https://updates.jenkins.io/latest/docker-workflow.hpi
    echo "Plugins installed successfully!"
'

# Restart Jenkins to load plugins
echo "🔄 Restarting Jenkins to load plugins..."
kubectl rollout restart deployment/jenkins -n jenkins

# Wait for Jenkins to be ready again
echo "⏳ Waiting for Jenkins to be ready after restart..."
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins

# Set up automatic port forwarding
echo "🌐 Setting up automatic port forwarding..."
cat > /home/ec2-user/setup-port-forwarding.sh << 'EOF'
#!/bin/bash
# Auto port forwarding script
while true; do
    kubectl port-forward --address 0.0.0.0 -n jenkins svc/jenkins 8081:8080 2>/dev/null || true
    sleep 5
done
EOF

chmod +x /home/ec2-user/setup-port-forwarding.sh

# Start port forwarding in background
nohup /home/ec2-user/setup-port-forwarding.sh > /var/log/port-forward.log 2>&1 &

echo "✅ Jenkins plugins installed and port forwarding started!"
echo "🔌 Jenkins plugins installed and ready!"
echo "📋 Pipeline as Code is ready to use!"
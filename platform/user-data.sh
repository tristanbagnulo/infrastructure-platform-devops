#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "🚀 Starting Golden Path Platform setup..."

# Update system (Amazon Linux)
yum update -y

# Install essential packages
yum install -y \
    curl \
    git \
    unzip \
    python3 \
    python3-pip \
    jq \
    docker

# Start Docker service (already installed via yum)
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Terraform
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Python packages for the infrastructure runner
pip3 install jsonschema pyyaml

# Create kind cluster config for the platform
cat > /home/ec2-user/kind-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: golden-path
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 6443
    hostPort: 6443
    protocol: TCP
  - containerPort: 8080
    hostPort: 8080
    protocol: TCP
EOF

# Create platform manifests directory
mkdir -p /home/ec2-user/platform-manifests

# Create Jenkins deployment
cat > /home/ec2-user/platform-manifests/jenkins.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
        - containerPort: 50000
        env:
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=false"
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
      volumes:
      - name: jenkins-home
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
  selector:
    app: jenkins
---
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins
EOF

# Create External Secrets Operator installation
cat > /home/ubuntu/platform-manifests/external-secrets.yaml << 'EOF'
# This will be installed via Helm in the setup script
# helm repo add external-secrets https://charts.external-secrets.io
# helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace
EOF

# Create setup script for the platform admin
cat > /home/ec2-user/setup-platform.sh << 'EOF'
#!/bin/bash
set -e

echo "🎯 Setting up Golden Path Platform..."

# Wait for Docker to be ready
echo "⏳ Waiting for Docker..."
while ! docker ps > /dev/null 2>&1; do
  sleep 2
done

# Create kind cluster
echo "🏗️ Creating kind cluster..."
kind create cluster --name golden-path --config /home/ec2-user/kind-config.yaml

# Set up kubeconfig
mkdir -p /home/ec2-user/.kube
kind get kubeconfig --name golden-path > /home/ec2-user/.kube/config
chmod 600 /home/ec2-user/.kube/config

# Install NGINX Ingress
echo "🌐 Installing NGINX Ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

# Install External Secrets Operator
echo "🔐 Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace

# Install Jenkins
echo "🏗️ Installing Jenkins..."
kubectl apply -f /home/ec2-user/platform-manifests/jenkins.yaml
kubectl wait --namespace jenkins --for=condition=ready pod --selector=app=jenkins --timeout=180s

# Clone the Golden Path repositories (if accessible)
echo "📦 Setting up workspace..."
mkdir -p /home/ec2-user/workspace
cd /home/ec2-user/workspace

echo "✅ Golden Path Platform setup complete!"
echo ""
echo "🎯 Platform Access:"
echo "  • Kubernetes API: https://$(curl -s ifconfig.me):6443"
echo "  • Jenkins: http://$(curl -s ifconfig.me):8080"
echo "  • SSH: ssh -i ~/.ssh/YOUR_KEY.pem ubuntu@$(curl -s ifconfig.me)"
echo ""
echo "🚀 Next steps:"
echo "  1. Clone your Golden Path repositories to /home/ubuntu/workspace/"
echo "  2. Configure Jenkins with your repositories"
echo "  3. Test the infrastructure runner with sample applications"
EOF

chmod +x /home/ec2-user/setup-platform.sh

# Set ownership
chown -R ec2-user:ec2-user /home/ec2-user/

# Configure AWS region for CLI
mkdir -p /home/ec2-user/.aws
cat > /home/ec2-user/.aws/config << EOF
[default]
region = ${aws_region}
EOF
chown -R ec2-user:ec2-user /home/ec2-user/.aws

# Wait for Docker to be ready
systemctl enable docker
systemctl start docker

# Verify installations
echo "✅ Installation verification:"
echo "Docker version: $(docker --version)"
echo "kubectl version: $(kubectl version --client --short)"
echo "kind version: $(kind version)"
echo "helm version: $(helm version --short)"
echo "terraform version: $(terraform version)"
echo "aws version: $(aws --version)"

echo "🎯 Golden Path Platform base setup complete!"
echo "👉 Run '/home/ec2-user/setup-platform.sh' to complete the setup"
echo "📝 Log: tail -f /var/log/user-data.log"

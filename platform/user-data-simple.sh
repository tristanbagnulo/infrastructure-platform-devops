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

# Start Docker service
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

# Create workspace directory
mkdir -p /home/ec2-user/workspace
cd /home/ec2-user/workspace

# Download and run the full setup script
echo "📥 Downloading full setup script..."
curl -L -o /home/ec2-user/setup-platform.sh https://raw.githubusercontent.com/your-org/infra-project/main/infrastructure-platform-devops/platform/setup-platform.sh
chmod +x /home/ec2-user/setup-platform.sh

# Download Jenkins plugin installation script
echo "📥 Downloading Jenkins plugin installation script..."
curl -L -o /home/ec2-user/install-jenkins-plugins.sh https://raw.githubusercontent.com/your-org/infra-project/main/infrastructure-platform-devops/platform/install-jenkins-plugins.sh
chmod +x /home/ec2-user/install-jenkins-plugins.sh

# Create auto-setup script that runs on boot
cat > /home/ec2-user/auto-setup.sh << 'EOF'
#!/bin/bash
# Auto-setup script that runs after instance is ready
sleep 30  # Wait for cloud-init to complete

# Check if setup has already been run
if [ -f /home/ec2-user/.setup-complete ]; then
    echo "Setup already completed, skipping..."
    exit 0
fi

echo "🚀 Starting automatic Golden Path Platform setup..."
cd /home/ec2-user
./setup-platform.sh

# Install Jenkins plugins and set up port forwarding
echo "🔌 Installing Jenkins plugins and setting up port forwarding..."
./install-jenkins-plugins.sh

# Mark setup as complete
touch /home/ec2-user/.setup-complete
echo "✅ Automatic setup completed!"
EOF

chmod +x /home/ec2-user/auto-setup.sh

# Set ownership
chown -R ec2-user:ec2-user /home/ec2-user/

# Schedule auto-setup to run after boot
echo "@reboot ec2-user /home/ec2-user/auto-setup.sh >> /home/ec2-user/setup.log 2>&1" | crontab -u ec2-user -

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
echo "🔄 Full setup will continue automatically after reboot..."

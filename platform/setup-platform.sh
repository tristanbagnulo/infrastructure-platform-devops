#!/bin/bash
set -e

echo "🔧 Setting up Golden Path Platform..."

# Wait for Docker to be ready
echo "⏳ Waiting for Docker..."
while ! docker ps > /dev/null 2>&1; do
    sleep 2
done

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

# Create Jenkins PVC for persistent storage
cat > /home/ec2-user/platform-manifests/jenkins-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
EOF

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
        image: jenkins/jenkins:lts-jdk11
        ports:
        - containerPort: 8080
        - containerPort: 50000
        env:
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=false"
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: terraform-bin
          mountPath: /usr/local/bin/terraform
          subPath: terraform
        - name: aws-cli
          mountPath: /usr/local/bin/aws
          subPath: aws
        - name: jq-bin
          mountPath: /usr/local/bin/jq
          subPath: jq
        - name: kubectl-bin
          mountPath: /usr/local/bin/kubectl
          subPath: kubectl
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
      - name: terraform-bin
        hostPath:
          path: /usr/bin/terraform
      - name: aws-cli
        hostPath:
          path: /usr/local/bin/aws
      - name: jq-bin
        hostPath:
          path: /usr/bin/jq
      - name: kubectl-bin
        hostPath:
          path: /usr/local/bin/kubectl
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
cat > /home/ec2-user/platform-manifests/external-secrets.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets
  namespace: external-secrets-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-secrets
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["external-secrets.io"]
  resources: ["secretstores", "clustersecretstores", "externalsecrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-secrets
subjects:
- kind: ServiceAccount
  name: external-secrets
  namespace: external-secrets-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-secrets
  namespace: external-secrets-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: external-secrets
  template:
    metadata:
      labels:
        app: external-secrets
    spec:
      serviceAccountName: external-secrets
      containers:
      - name: external-secrets
        image: external-secrets/external-secrets:v0.9.11
        ports:
        - containerPort: 8080
        env:
        - name: LOG_LEVEL
          value: "info"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

# Create kind cluster
echo "🏗️ Creating kind cluster..."
kind create cluster --name golden-path --config /home/ec2-user/kind-config.yaml

# Set up kubectl config
mkdir -p /home/ec2-user/.kube
kind get kubeconfig --name golden-path > /home/ec2-user/.kube/config
chmod 600 /home/ec2-user/.kube/config

# Install NGINX Ingress
echo "🌐 Installing NGINX Ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

# Install External Secrets Operator
echo "🔐 Installing External Secrets Operator..."
kubectl apply -f /home/ec2-user/platform-manifests/external-secrets.yaml
kubectl wait --namespace external-secrets-system --for=condition=ready pod --selector=app=external-secrets --timeout=120s

# Install Jenkins
echo "🔧 Installing Jenkins..."
kubectl apply -f /home/ec2-user/platform-manifests/jenkins-pvc.yaml
kubectl apply -f /home/ec2-user/platform-manifests/jenkins.yaml
kubectl wait --namespace jenkins --for=condition=ready pod --selector=app=jenkins --timeout=180s

# Set up workspace
echo "📁 Setting up workspace..."
mkdir -p /home/ec2-user/workspace
cd /home/ec2-user/workspace

echo "✅ Golden Path Platform setup complete!"
echo ""
echo "🎯 Platform Access:"
echo "  • Kubernetes API: https://$(curl -s ifconfig.me):6443"
echo "  • Jenkins: http://$(curl -s ifconfig.me):8081"
echo "  • SSH: ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@$(curl -s ifconfig.me)"
echo ""
echo "🚀 Next steps:"
echo "  1. Clone your Golden Path repositories to /home/ec2-user/workspace/"
echo "  2. Configure Jenkins with your repositories"
echo "  3. Test the infrastructure runner with sample applications"

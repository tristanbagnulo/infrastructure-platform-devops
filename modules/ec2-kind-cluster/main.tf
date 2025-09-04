# EC2 instance to host kind cluster instead of EKS
# Cost-effective alternative for demos and development

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "kind_cluster" {
  name_prefix = "${var.app}-${var.env}-kind-"
  description = "Security group for kind cluster EC2 instance"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS for applications
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort range
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app}-${var.env}-kind-sg"
    App  = var.app
    Env  = var.env
  }
}

# User data script to install Docker and kind
locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = "${var.app}-${var.env}"
  }))
}

resource "aws_instance" "kind_cluster" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.kind_cluster.id]
  subnet_id              = var.subnet_id

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.disk_size
    encrypted   = true
  }

  tags = {
    Name = "${var.app}-${var.env}-kind-cluster"
    App  = var.app
    Env  = var.env
    Type = "kind-cluster"
  }

  # Wait for instance to be ready
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo systemctl is-active docker",
      "kind version"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

# Create kind cluster after instance is ready
resource "null_resource" "kind_cluster_setup" {
  depends_on = [aws_instance.kind_cluster]

  provisioner "remote-exec" {
    inline = [
      "kind create cluster --name ${var.app}-${var.env} --config /home/ubuntu/kind-config.yaml",
      "kubectl cluster-info --context kind-${var.app}-${var.env}",
      # Install essential add-ons
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml",
      "kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.kind_cluster.public_ip
    }
  }

  triggers = {
    instance_id = aws_instance.kind_cluster.id
  }
}

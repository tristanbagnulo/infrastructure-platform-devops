output "instance_id" {
  description = "ID of the EC2 instance hosting the kind cluster"
  value       = aws_instance.kind_cluster.id
}

output "public_ip" {
  description = "Public IP address of the kind cluster instance"
  value       = aws_instance.kind_cluster.public_ip
}

output "private_ip" {
  description = "Private IP address of the kind cluster instance"
  value       = aws_instance.kind_cluster.private_ip
}

output "security_group_id" {
  description = "ID of the security group for the kind cluster"
  value       = aws_security_group.kind_cluster.id
}

output "cluster_name" {
  description = "Name of the kind cluster"
  value       = "${var.app}-${var.env}"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig for the kind cluster"
  value       = "kind get kubeconfig --name ${var.app}-${var.env}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.kind_cluster.public_ip}"
}

output "kubernetes_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${aws_instance.kind_cluster.public_ip}:6443"
}

# For IRSA compatibility - simulate EKS OIDC issuer
output "oidc_issuer_url" {
  description = "OIDC issuer URL for service account tokens (simulated for kind)"
  value       = "https://${aws_instance.kind_cluster.public_ip}:6443"
}

output "cluster_arn" {
  description = "Simulated cluster ARN for compatibility"
  value       = "arn:aws:kind:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.app}-${var.env}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

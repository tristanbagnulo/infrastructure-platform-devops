output "platform_public_ip" {
  description = "Public IP address of the Golden Path platform"
  value       = aws_instance.platform.public_ip
}

output "platform_private_ip" {
  description = "Private IP address of the platform"
  value       = aws_instance.platform.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to the platform"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.platform.public_ip}"
}

output "kubernetes_endpoint" {
  description = "Kubernetes API endpoint (after kind cluster is created)"
  value       = "https://${aws_instance.platform.public_ip}:6443"
}

output "jenkins_url" {
  description = "Jenkins URL (after setup)"
  value       = "http://${aws_instance.platform.public_ip}:8080"
}

output "platform_instance_id" {
  description = "EC2 instance ID of the platform"
  value       = aws_instance.platform.id
}

output "setup_instructions" {
  description = "Instructions to complete platform setup"
  value       = <<-EOT
    1. SSH to the platform: ${local.ssh_command}
    2. Wait for setup to complete: tail -f /var/log/cloud-init-output.log
    3. Create kind cluster: kind create cluster --name golden-path --config /home/ubuntu/kind-config.yaml
    4. Install platform components: kubectl apply -f /home/ubuntu/platform-manifests/
    5. Access Jenkins: http://${aws_instance.platform.public_ip}:8080
  EOT
}

locals {
  ssh_command = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.platform.public_ip}"
}

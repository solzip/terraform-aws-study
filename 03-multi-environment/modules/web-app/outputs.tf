# modules/web-app/outputs.tf
# 웹 앱 모듈의 출력 값

output "instance_id" {
  description = "앱 EC2 인스턴스 ID"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "앱 EC2 인스턴스 Public IP"
  value       = aws_instance.app.public_ip
}

output "instance_private_ip" {
  description = "앱 EC2 인스턴스 Private IP"
  value       = aws_instance.app.private_ip
}

output "security_group_id" {
  description = "앱 Security Group ID"
  value       = aws_security_group.app.id
}

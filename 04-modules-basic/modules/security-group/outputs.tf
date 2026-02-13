# modules/security-group/outputs.tf
# Security Group 모듈 출력 값

output "security_group_id" {
  description = "Web Security Group의 ID"
  value       = aws_security_group.web.id
}

output "security_group_name" {
  description = "Web Security Group의 이름"
  value       = aws_security_group.web.name
}

# ==========================================
# modules/security/outputs.tf - 보안 모듈 출력값
# ==========================================

output "web_sg_id" {
  description = "웹 서버 Security Group ID"
  value       = aws_security_group.web.id
}

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 Instance Profile 이름 - EC2 생성 시 사용"
  value       = aws_iam_instance_profile.ec2.name
}

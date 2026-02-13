# ==========================================
# outputs.tf - 출력 값 정의
# ==========================================

# ==========================================
# IAM 관련
# ==========================================

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = module.iam.ec2_role_arn
}

output "ec2_instance_profile_name" {
  description = "EC2 Instance Profile 이름"
  value       = module.iam.ec2_instance_profile_name
}

# ==========================================
# KMS 관련
# ==========================================

output "kms_key_id" {
  description = "KMS 키 ID"
  value       = module.kms.key_id
}

output "kms_key_arn" {
  description = "KMS 키 ARN"
  value       = module.kms.key_arn
}

output "kms_alias" {
  description = "KMS 키 Alias"
  value       = module.kms.alias_name
}

# ==========================================
# Secrets Manager 관련
# ==========================================

output "db_password_secret_name" {
  description = "DB 비밀번호 Secret 이름"
  value       = module.secrets.db_password_secret_name
}

output "api_key_secret_name" {
  description = "API 키 Secret 이름"
  value       = module.secrets.api_key_secret_name
}

# ==========================================
# 인프라 관련
# ==========================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "EC2 Public IP"
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "웹 서버 URL"
  value       = "http://${aws_instance.web.public_ip}"
}

output "security_summary" {
  description = "보안 구성 요약"
  value       = <<-EOT

  ============================================
   Security Configuration Summary
  ============================================
   IAM Role:         ${module.iam.ec2_role_name}
   KMS Key:          ${module.kms.alias_name}
   Secrets:          ${module.secrets.db_password_secret_name}
                     ${module.secrets.api_key_secret_name}
   SG:               ${aws_security_group.web.name}
   EBS Encryption:   Customer Managed KMS Key
   IMDSv2:           Required
  ============================================

  EOT
}

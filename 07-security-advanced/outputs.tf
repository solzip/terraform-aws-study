# ==========================================
# outputs.tf - 출력 값 정의
# ==========================================
#
# terraform apply 완료 후 표시되는 중요한 정보들입니다.
# 다른 Terraform 프로젝트에서 terraform_remote_state로
# 참조할 수도 있습니다.

# ==========================================
# IAM 관련
# ==========================================

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN (ABAC + Permission Boundary 적용)"
  value       = module.iam_policies.ec2_role_arn
}

output "ec2_instance_profile_name" {
  description = "EC2 Instance Profile 이름"
  value       = module.iam_policies.ec2_instance_profile_name
}

output "permission_boundary_arn" {
  description = "Permission Boundary 정책 ARN"
  value       = module.iam_policies.permission_boundary_arn
}

# ==========================================
# KMS 관련
# ==========================================

output "kms_main_key_arn" {
  description = "범용 KMS 키 ARN"
  value       = module.kms.main_key_arn
}

output "kms_secrets_key_arn" {
  description = "Secrets Manager 전용 KMS 키 ARN"
  value       = module.kms.secrets_key_arn
}

# ==========================================
# Secrets Manager 관련
# ==========================================

output "db_secret_name" {
  description = "DB 자격증명 Secret 이름"
  value       = module.secrets_manager.db_secret_name
}

output "api_secret_name" {
  description = "API 자격증명 Secret 이름"
  value       = module.secrets_manager.api_secret_name
}

output "rotation_lambda_name" {
  description = "Secret 로테이션 Lambda 함수 이름"
  value       = module.secrets_manager.rotation_lambda_name
}

# ==========================================
# VPC Flow Logs 관련
# ==========================================

output "flow_logs_log_group" {
  description = "VPC Flow Logs CloudWatch Log Group 이름"
  value       = var.enable_vpc_flow_logs ? module.vpc_flow_logs[0].log_group_name : "disabled"
}

# ==========================================
# GuardDuty 관련
# ==========================================

output "guardduty_detector_id" {
  description = "GuardDuty Detector ID"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : "disabled"
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

output "sns_topic_arn" {
  description = "보안 알림 SNS Topic ARN"
  value       = aws_sns_topic.security_alerts.arn
}

# ==========================================
# 보안 구성 요약
# ==========================================

output "security_summary" {
  description = "보안 구성 요약"
  value       = <<-EOT

  ============================================
   Security Advanced Configuration Summary
  ============================================
   IAM Role:           ${module.iam_policies.ec2_role_name} (ABAC + Boundary)
   KMS Main Key:       ${module.kms.main_alias_name}
   KMS Secrets Key:    ${module.kms.secrets_alias_name}
   DB Secret:          ${module.secrets_manager.db_secret_name}
   API Secret:         ${module.secrets_manager.api_secret_name}
   Rotation Lambda:    ${module.secrets_manager.rotation_lambda_name}
   VPC Flow Logs:      ${var.enable_vpc_flow_logs ? "Enabled" : "Disabled"}
   GuardDuty:          ${var.enable_guardduty ? "Enabled" : "Disabled"}
   Config Rules:       ${var.enable_config_rules ? "Enabled" : "Disabled"}
   Security Hub:       ${var.enable_security_hub ? "Enabled" : "Disabled"}
   SNS Alerts:         ${aws_sns_topic.security_alerts.name}
   EBS Encryption:     Customer Managed KMS Key
   IMDSv2:             Required
  ============================================

  EOT
}

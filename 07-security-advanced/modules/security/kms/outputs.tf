# ==========================================
# modules/security/kms/outputs.tf
# ==========================================

# ==========================================
# 메인 키 (범용) 출력
# ==========================================

output "main_key_id" {
  description = "범용 KMS 키 ID"
  value       = aws_kms_key.main.key_id
}

output "main_key_arn" {
  description = "범용 KMS 키 ARN"
  value       = aws_kms_key.main.arn
}

output "main_alias_name" {
  description = "범용 KMS 키 Alias 이름"
  value       = aws_kms_alias.main.name
}

# ==========================================
# Secrets Manager 전용 키 출력
# ==========================================

output "secrets_key_id" {
  description = "Secrets Manager 전용 KMS 키 ID"
  value       = aws_kms_key.secrets.key_id
}

output "secrets_key_arn" {
  description = "Secrets Manager 전용 KMS 키 ARN"
  value       = aws_kms_key.secrets.arn
}

output "secrets_alias_name" {
  description = "Secrets Manager 전용 KMS 키 Alias 이름"
  value       = aws_kms_alias.secrets.name
}

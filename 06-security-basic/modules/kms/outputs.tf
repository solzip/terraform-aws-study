# ==========================================
# modules/kms/outputs.tf - KMS 모듈 출력 값
# ==========================================

output "key_id" {
  description = "KMS 키의 ID (UUID 형식)"
  value       = aws_kms_key.main.key_id
}

output "key_arn" {
  description = "KMS 키의 ARN (다른 서비스에서 참조할 때 사용)"
  value       = aws_kms_key.main.arn
}

output "alias_name" {
  description = "KMS 키의 Alias 이름"
  value       = aws_kms_alias.main.name
}

output "alias_arn" {
  description = "KMS Alias의 ARN"
  value       = aws_kms_alias.main.arn
}

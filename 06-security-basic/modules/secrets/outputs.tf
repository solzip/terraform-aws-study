# ==========================================
# modules/secrets/outputs.tf - Secrets Manager 모듈 출력 값
# ==========================================

output "db_password_secret_arn" {
  description = "DB 비밀번호 Secret의 ARN"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_name" {
  description = "DB 비밀번호 Secret의 이름"
  value       = aws_secretsmanager_secret.db_password.name
}

output "api_key_secret_arn" {
  description = "API 키 Secret의 ARN"
  value       = aws_secretsmanager_secret.api_key.arn
}

output "api_key_secret_name" {
  description = "API 키 Secret의 이름"
  value       = aws_secretsmanager_secret.api_key.name
}

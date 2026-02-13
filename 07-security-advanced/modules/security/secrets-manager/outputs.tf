# ==========================================
# modules/security/secrets-manager/outputs.tf
# ==========================================
#
# 이 모듈이 외부로 노출하는 값들입니다.
# 루트 모듈이나 다른 모듈에서 이 값들을 참조할 수 있습니다.
#
# 주의: Secret 값 자체(비밀번호)는 절대 output으로 노출하지 않습니다!
#       ARN, 이름 등 메타데이터만 노출합니다.

output "db_secret_arn" {
  description = "DB 자격증명 Secret의 ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_secret_name" {
  description = "DB 자격증명 Secret의 이름"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "api_secret_arn" {
  description = "API 자격증명 Secret의 ARN"
  value       = aws_secretsmanager_secret.api_credentials.arn
}

output "api_secret_name" {
  description = "API 자격증명 Secret의 이름"
  value       = aws_secretsmanager_secret.api_credentials.name
}

output "rotation_lambda_arn" {
  description = "Secret 로테이션 Lambda 함수의 ARN"
  value       = aws_lambda_function.secret_rotation.arn
}

output "rotation_lambda_name" {
  description = "Secret 로테이션 Lambda 함수의 이름"
  value       = aws_lambda_function.secret_rotation.function_name
}

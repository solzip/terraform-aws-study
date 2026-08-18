# ==========================================
# modules/monitoring/logs/outputs.tf
# ==========================================
#
# 로그 그룹 "이름"과 "ARN"을 모두 출력합니다.
#   - 이름: Metric Filter, CloudWatch Agent 설정에서 사용
#   - ARN : IAM 정책에서 특정 로그 그룹에만 권한을 줄 때 사용

# ==========================================
# 로그 그룹 이름
# ==========================================

output "app_log_group_name" {
  description = "애플리케이션 로그 그룹 이름 (Metric Filter가 참조)"
  value       = aws_cloudwatch_log_group.application.name
}

output "system_log_group_name" {
  description = "시스템 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.system.name
}

output "access_log_group_name" {
  description = "접근 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.access.name
}

output "error_log_group_name" {
  description = "에러 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.error.name
}

# ==========================================
# 로그 그룹 ARN
# ==========================================
#
# IAM 정책에서 사용할 때는 뒤에 :* 를 붙여야
# 그룹 안의 모든 로그 스트림에 권한이 적용됩니다.
#   예: "${module.logs.app_log_group_arn}:*"

output "app_log_group_arn" {
  description = "애플리케이션 로그 그룹 ARN"
  value       = aws_cloudwatch_log_group.application.arn
}

output "system_log_group_arn" {
  description = "시스템 로그 그룹 ARN"
  value       = aws_cloudwatch_log_group.system.arn
}

output "access_log_group_arn" {
  description = "접근 로그 그룹 ARN"
  value       = aws_cloudwatch_log_group.access.arn
}

output "error_log_group_arn" {
  description = "에러 로그 그룹 ARN"
  value       = aws_cloudwatch_log_group.error.arn
}

# ==========================================
# 전체 목록
# ==========================================
#
# CloudWatch Agent 설정 파일을 만들거나
# 로그 그룹 목록을 한눈에 확인할 때 사용합니다.

output "log_group_names" {
  description = "생성된 모든 로그 그룹 이름 (용도 => 이름)"
  value = {
    application = aws_cloudwatch_log_group.application.name
    system      = aws_cloudwatch_log_group.system.name
    access      = aws_cloudwatch_log_group.access.name
    error       = aws_cloudwatch_log_group.error.name
  }
}

# ==========================================
# modules/monitoring/cloudwatch/outputs.tf
# ==========================================

output "cpu_alarm_arn" {
  description = "CPU 사용률 알람 ARN"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "status_check_alarm_arn" {
  description = "StatusCheck 실패 알람 ARN"
  value       = aws_cloudwatch_metric_alarm.status_check_failed.arn
}

output "network_alarm_arn" {
  description = "네트워크 트래픽 알람 ARN"
  value       = aws_cloudwatch_metric_alarm.network_out_high.arn
}

output "dashboard_name" {
  description = "CloudWatch Dashboard 이름"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : "disabled"
}

# ==========================================
# modules/security/vpc-flow-logs/outputs.tf
# ==========================================

output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.vpc.id
}

output "log_group_name" {
  description = "Flow Logs가 저장되는 CloudWatch Log Group 이름"
  value       = aws_cloudwatch_log_group.flow_logs.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = aws_cloudwatch_log_group.flow_logs.arn
}

output "alarm_arn" {
  description = "거부된 트래픽 알림 CloudWatch Alarm ARN"
  value       = aws_cloudwatch_metric_alarm.high_rejected_traffic.arn
}

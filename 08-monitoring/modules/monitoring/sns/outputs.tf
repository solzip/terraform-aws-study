# ==========================================
# modules/monitoring/sns/outputs.tf
# ==========================================

output "monitoring_topic_arn" {
  description = "모니터링 알림 SNS Topic ARN"
  value       = aws_sns_topic.monitoring_alerts.arn
}

output "monitoring_topic_name" {
  description = "모니터링 알림 SNS Topic 이름"
  value       = aws_sns_topic.monitoring_alerts.name
}

output "critical_topic_arn" {
  description = "긴급 알림 SNS Topic ARN"
  value       = aws_sns_topic.critical_alerts.arn
}

output "critical_topic_name" {
  description = "긴급 알림 SNS Topic 이름"
  value       = aws_sns_topic.critical_alerts.name
}

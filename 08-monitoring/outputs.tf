# ==========================================
# outputs.tf - 출력 값 정의
# ==========================================

# ==========================================
# 인프라
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

# ==========================================
# SNS
# ==========================================

output "monitoring_topic_arn" {
  description = "모니터링 알림 SNS Topic ARN"
  value       = module.sns.monitoring_topic_arn
}

output "critical_topic_arn" {
  description = "긴급 알림 SNS Topic ARN"
  value       = module.sns.critical_topic_arn
}

# ==========================================
# CloudWatch
# ==========================================

output "dashboard_name" {
  description = "CloudWatch Dashboard 이름"
  value       = module.cloudwatch.dashboard_name
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = var.enable_dashboard ? "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-${var.environment}-overview" : "Dashboard disabled"
}

# ==========================================
# CloudTrail
# ==========================================

output "cloudtrail_name" {
  description = "CloudTrail 이름"
  value       = var.enable_cloudtrail ? module.cloudtrail[0].trail_name : "disabled"
}

output "cloudtrail_bucket" {
  description = "CloudTrail 로그 S3 버킷"
  value       = var.enable_cloudtrail ? module.cloudtrail[0].s3_bucket_name : "disabled"
}

# ==========================================
# Logs
# ==========================================

output "log_groups" {
  description = "생성된 CloudWatch Log Group 목록"
  value = {
    application = module.logs.app_log_group_name
    system      = module.logs.system_log_group_name
    access      = module.logs.access_log_group_name
    error       = module.logs.error_log_group_name
  }
}

# ==========================================
# 모니터링 구성 요약
# ==========================================

output "monitoring_summary" {
  description = "모니터링 구성 요약"
  value       = <<-EOT

  ============================================
   Monitoring Configuration Summary
  ============================================
   EC2 Instance:       ${aws_instance.web.id}
   Detailed Monitor:   Enabled (1-min interval)

   Alarms:
     CPU High:         > ${var.cpu_alarm_threshold}%
     Status Check:     Any failure
     Network Out:      > 100MB/5min
     App Errors:       > 10/5min

   SNS Topics:
     Monitoring:       ${module.sns.monitoring_topic_name}
     Critical:         ${module.sns.critical_topic_name}

   Dashboard:          ${var.enable_dashboard ? "Enabled" : "Disabled"}
   CloudTrail:         ${var.enable_cloudtrail ? "Enabled" : "Disabled"}

   Log Groups:         4 (app, system, access, error)
   Log Retention:      ${var.log_retention_days} days
  ============================================

  EOT
}

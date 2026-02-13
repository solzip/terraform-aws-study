# ==========================================
# modules/monitoring/cloudtrail/outputs.tf
# ==========================================

output "trail_arn" {
  description = "CloudTrail ARN"
  value       = aws_cloudtrail.main.arn
}

output "trail_name" {
  description = "CloudTrail 이름"
  value       = aws_cloudtrail.main.name
}

output "s3_bucket_name" {
  description = "CloudTrail 로그 S3 버킷 이름"
  value       = aws_s3_bucket.cloudtrail.id
}

output "log_group_name" {
  description = "CloudTrail CloudWatch 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

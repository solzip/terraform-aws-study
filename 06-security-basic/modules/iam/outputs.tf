# ==========================================
# modules/iam/outputs.tf - IAM 모듈 출력 값
# ==========================================
#
# 다른 모듈에서 IAM Role과 Instance Profile을 참조할 수 있도록
# 필요한 값을 내보냅니다.

output "ec2_role_arn" {
  description = "EC2 IAM Role의 ARN (Amazon Resource Name)"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_role_name" {
  description = "EC2 IAM Role의 이름"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_instance_profile_name" {
  description = "EC2 Instance Profile의 이름 (EC2에 연결할 때 사용)"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_instance_profile_arn" {
  description = "EC2 Instance Profile의 ARN"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "s3_read_only_policy_arn" {
  description = "S3 읽기 전용 정책의 ARN"
  value       = aws_iam_policy.s3_read_only.arn
}

output "cloudwatch_logs_policy_arn" {
  description = "CloudWatch Logs 정책의 ARN"
  value       = aws_iam_policy.cloudwatch_logs.arn
}

output "secrets_read_policy_arn" {
  description = "Secrets Manager 읽기 정책의 ARN"
  value       = aws_iam_policy.secrets_read.arn
}

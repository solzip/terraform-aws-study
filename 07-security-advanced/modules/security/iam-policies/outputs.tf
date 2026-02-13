# ==========================================
# modules/security/iam-policies/outputs.tf
# ==========================================

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_role_name" {
  description = "EC2 IAM Role 이름"
  value       = aws_iam_role.ec2_role.name
}

output "ec2_instance_profile_name" {
  description = "EC2 Instance Profile 이름"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "permission_boundary_arn" {
  description = "Permission Boundary 정책 ARN"
  value       = aws_iam_policy.permission_boundary.arn
}

output "s3_abac_policy_arn" {
  description = "S3 ABAC 정책 ARN"
  value       = aws_iam_policy.s3_abac.arn
}

output "secrets_policy_arn" {
  description = "Secrets Manager 조건부 접근 정책 ARN"
  value       = aws_iam_policy.secrets_conditional.arn
}

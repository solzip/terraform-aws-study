# ==========================================
# outputs.tf - 출력 값 정의
# ==========================================
#
# CI/CD 파이프라인에서 outputs는 특히 중요합니다:
#   - terraform output으로 배포 결과를 확인
#   - 다음 배포 단계에서 참조 (예: ALB DNS → Route53)
#   - PR 코멘트에 배포 결과 표시

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

output "deployment_info" {
  description = "배포 정보 요약"
  value       = <<-EOT

  ============================================
   CI/CD Deployment Summary
  ============================================
   Environment:  ${var.environment}
   Instance:     ${aws_instance.web.id}
   Public IP:    ${aws_instance.web.public_ip}
   URL:          http://${aws_instance.web.public_ip}
   Deployed By:  GitHub Actions
  ============================================

  EOT
}


# 출력 값 정의

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "EC2 Instance ID (메타데이터만)"
  value       = aws_instance.web.id
}

output "localstack_endpoint" {
  description = "LocalStack 엔드포인트"
  value       = "http://localhost:4566"
}

output "deployment_info" {
  description = "배포 정보"
  value       = <<-EOT

  ╔════════════════════════════════════════════════════════╗
  ║     LocalStack 환경에서 Terraform 배포 완료! 🎉       ║
  ╠════════════════════════════════════════════════════════╣
  ║                                                        ║
  ║  LocalStack: http://localhost:4566                    ║
  ║  VPC ID:     ${aws_vpc.main.id}                       ║
  ║  Instance:   ${aws_instance.web.id}                   ║
  ║                                                        ║
  ║  💡 LocalStack은 실제 서버를 실행하지 않습니다        ║
  ║  💡 메타데이터만 저장되며 비용이 발생하지 않습니다    ║
  ║                                                        ║
  ║  확인: make check                                      ║
  ║  정리: make clean                                      ║
  ║                                                        ║
  ╚════════════════════════════════════════════════════════╝

  EOT
}
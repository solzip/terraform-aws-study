# outputs.tf
# 멀티 환경 배포 후 출력 값 정의

# ==========================================
# VPC 관련 출력
# ==========================================

output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

# ==========================================
# Subnet 관련 출력
# ==========================================

output "public_subnet_ids" {
  description = "Public Subnet ID 목록"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "Public Subnet CIDR 목록"
  value       = aws_subnet.public[*].cidr_block
}

# ==========================================
# EC2 관련 출력
# ==========================================

output "instance_ids" {
  description = "EC2 인스턴스 ID 목록"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "EC2 인스턴스 Public IP 목록"
  value       = aws_instance.web[*].public_ip
}

output "instance_private_ips" {
  description = "EC2 인스턴스 Private IP 목록"
  value       = aws_instance.web[*].private_ip
}

# ==========================================
# EIP 관련 출력 (Prod 전용)
# ==========================================

output "elastic_ips" {
  description = "Elastic IP 목록 (Prod 환경에서만 생성)"
  value       = aws_eip.web[*].public_ip
}

# ==========================================
# Security Group 출력
# ==========================================

output "security_group_id" {
  description = "Web Security Group ID"
  value       = aws_security_group.web.id
}

# ==========================================
# Module 출력
# ==========================================

output "web_app_instance_id" {
  description = "web-app 모듈로 생성된 인스턴스 ID"
  value       = module.web_app.instance_id
}

output "web_app_public_ip" {
  description = "web-app 모듈 인스턴스의 Public IP"
  value       = module.web_app.instance_public_ip
}

# ==========================================
# 환경 정보
# ==========================================

output "environment" {
  description = "현재 배포된 환경"
  value       = var.environment
}

output "deployment_summary" {
  description = "배포 요약"
  value       = <<-EOT

  ====================================
   ${upper(var.environment)} Environment Deployed
  ====================================
   VPC:        ${aws_vpc.main.id}
   Subnets:    ${local.actual_subnet_count}개
   Instances:  ${var.instance_count}대 (${var.instance_type})
   Monitoring: ${var.enable_monitoring ? "Enabled" : "Disabled"}
   Backup:     ${var.enable_backup ? "Enabled" : "Disabled"}
  ====================================

  EOT
}

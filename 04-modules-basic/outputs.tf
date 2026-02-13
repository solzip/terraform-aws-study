# outputs.tf
# 루트 모듈 출력 값 - 각 모듈의 출력을 상위로 전달

# ==========================================
# VPC 모듈 출력
# ==========================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = module.vpc.public_subnet_id
}

# ==========================================
# Security Group 모듈 출력
# ==========================================

output "security_group_id" {
  description = "Web Security Group ID"
  value       = module.security_group.security_group_id
}

# ==========================================
# EC2 모듈 출력
# ==========================================

output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2 인스턴스 Public IP"
  value       = module.ec2.public_ip
}

output "instance_public_dns" {
  description = "EC2 인스턴스 Public DNS"
  value       = module.ec2.public_dns
}

# ==========================================
# 편의 출력
# ==========================================

output "web_url" {
  description = "웹 서버 접속 URL"
  value       = "http://${module.ec2.public_ip}"
}

output "ssh_command" {
  description = "SSH 접속 명령어"
  value       = "ssh -i <your-key.pem> ec2-user@${module.ec2.public_ip}"
}

output "environment" {
  description = "배포된 환경"
  value       = var.environment
}

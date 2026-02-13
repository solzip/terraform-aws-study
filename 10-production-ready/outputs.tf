# ==========================================
# outputs.tf - 프로덕션 출력값 정의
# ==========================================
#
# 이 파일의 역할:
#   Terraform apply 후 중요한 정보를 표시합니다.
#   다른 Terraform 프로젝트에서 이 값들을 참조할 수도 있습니다.
#
# 출력값 설계 원칙:
#   1. 관리에 필요한 핵심 정보만 출력 (너무 많으면 복잡)
#   2. 민감한 정보는 sensitive = true 설정
#   3. description으로 각 출력값의 용도 설명
#   4. 구조화된 출력으로 가독성 향상

# ==========================================
# VPC 관련 출력값
# ==========================================

output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC의 CIDR 블록"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value       = module.vpc.public_subnet_ids
}

# ==========================================
# EC2 관련 출력값
# ==========================================

output "instance_ids" {
  description = "생성된 EC2 인스턴스 ID 목록"
  value       = module.ec2.instance_ids
}

output "instance_public_ips" {
  description = "EC2 인스턴스의 퍼블릭 IP 목록"
  value       = module.ec2.public_ips
}

# ==========================================
# 보안 관련 출력값
# ==========================================

output "web_security_group_id" {
  description = "웹 서버 보안 그룹 ID"
  value       = module.security.web_sg_id
}

# ==========================================
# 종합 정보 출력
# ==========================================
# 배포 후 한눈에 확인할 수 있는 요약 정보입니다.
# terraform output deployment_summary 로 확인할 수 있습니다.
output "deployment_summary" {
  description = "배포 환경 요약 정보"
  value = {
    project        = var.project_name
    environment    = var.environment
    region         = var.aws_region
    vpc_id         = module.vpc.vpc_id
    vpc_cidr       = module.vpc.vpc_cidr
    instance_count = var.instance_count
    instance_type  = var.instance_type
    instance_ids   = module.ec2.instance_ids
    public_ips     = module.ec2.public_ips
  }
}

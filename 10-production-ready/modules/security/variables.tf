# ==========================================
# modules/security/variables.tf - 보안 모듈 입력 변수
# ==========================================

variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "vpc_id" {
  description = "Security Group을 생성할 VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록 (내부 트래픽 규칙에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "SSH 접근을 허용할 CIDR 목록 (빈 목록이면 SSH 차단)"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}

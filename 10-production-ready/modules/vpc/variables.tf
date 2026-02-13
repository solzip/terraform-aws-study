# ==========================================
# modules/vpc/variables.tf - VPC 모듈 입력 변수
# ==========================================
#
# 모듈 변수 설계 원칙:
#   1. 모듈 사용자가 필요한 것만 노출
#   2. 내부 구현 세부사항은 숨김
#   3. 합리적인 기본값 제공 (가능한 경우)

variable "name_prefix" {
  description = "리소스 이름 접두사 (예: tf-study-dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록 (예: 10.0.0.0/16)"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록"
  type        = list(string)
}

variable "availability_zones" {
  description = "사용할 가용영역 목록"
  type        = list(string)
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}

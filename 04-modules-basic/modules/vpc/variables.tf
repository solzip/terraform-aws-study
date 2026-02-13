# modules/vpc/variables.tf
# VPC 모듈 입력 변수

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}

variable "environment" {
  description = "환경 구분 (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC의 CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다."
  }
}

variable "public_subnet_cidr" {
  description = "Public Subnet의 CIDR 블록"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다."
  }
}

variable "availability_zone" {
  description = "서브넷을 생성할 가용 영역 (null이면 자동 선택)"
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}

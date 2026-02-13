# variables.tf
# 루트 모듈 변수 - 각 모듈로 전달할 값을 정의

# ==========================================
# 기본 설정
# ==========================================

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "유효한 AWS 리전 형식이어야 합니다."
  }
}

variable "environment" {
  description = "환경 구분 (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "modules-basic"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "프로젝트 이름은 소문자, 숫자, 하이픈(-)만 사용 가능합니다."
  }
}

# ==========================================
# 네트워크 설정 (VPC 모듈로 전달)
# ==========================================

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR 블록"
  type        = string
  default     = "10.0.1.0/24"
}

# ==========================================
# EC2 설정 (EC2 모듈로 전달)
# ==========================================

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"
}

# ==========================================
# 보안 설정 (SG 모듈로 전달)
# ==========================================

variable "allowed_ssh_cidr_blocks" {
  description = "SSH 허용 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidr_blocks" {
  description = "HTTP 허용 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

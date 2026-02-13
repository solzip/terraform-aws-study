# ==========================================
# variables.tf - 입력 변수 정의
# ==========================================
#
# 보안 관련 리소스에서 사용하는 변수를 정의합니다.

# ==========================================
# 기본 설정 변수
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
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
  default     = "security-basic"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "프로젝트 이름은 소문자, 숫자, 하이픈만 사용 가능합니다."
  }
}

# ==========================================
# 네트워크 설정 변수
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
# EC2 설정 변수
# ==========================================

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"
}

# ==========================================
# 보안 설정 변수
# ==========================================

variable "allowed_ssh_cidr_blocks" {
  description = "SSH 접근을 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "kms_deletion_window_days" {
  description = "KMS 키 삭제 대기 기간 (일). 삭제 요청 후 이 기간 내에 복구 가능"
  type        = number
  default     = 7

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "KMS 삭제 대기 기간은 7~30일 사이여야 합니다."
  }
}

variable "enable_key_rotation" {
  description = "KMS 키 자동 교체 활성화 여부 (1년 주기)"
  type        = bool
  default     = true
}

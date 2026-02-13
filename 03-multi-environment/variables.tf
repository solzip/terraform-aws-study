# variables.tf
# 멀티 환경 관리를 위한 입력 변수 선언
# - 환경별 리소스 크기, 개수, 기능 토글 등을 변수로 관리

# ==========================================
# 기본 설정 변수
# ==========================================

# 환경 변수 (dev / staging / prod)
variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

# 프로젝트 이름
variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
  default     = "multi-env"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "프로젝트 이름은 소문자, 숫자, 하이픈(-)만 사용 가능합니다."
  }
}

# AWS 리전
variable "aws_region" {
  description = "AWS 리소스를 생성할 리전"
  type        = string
  default     = "ap-northeast-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "유효한 AWS 리전 형식이어야 합니다 (예: ap-northeast-2)."
  }
}

# ==========================================
# 네트워크 설정 변수
# ==========================================

# VPC CIDR 블록
variable "vpc_cidr" {
  description = "VPC의 CIDR 블록 (환경별로 다르게 설정)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다 (예: 10.0.0.0/16)."
  }
}

# Public Subnet CIDR 목록
variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR 블록 목록 (가용 영역별로 하나씩)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "모든 항목이 올바른 CIDR 형식이어야 합니다."
  }
}

# ==========================================
# EC2 인스턴스 설정 변수
# ==========================================

# 인스턴스 타입
variable "instance_type" {
  description = "EC2 인스턴스 타입 (환경별 사양 조정)"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t2.small", "t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "허용된 인스턴스 타입: t2.micro, t2.small, t3.micro, t3.small, t3.medium"
  }
}

# 인스턴스 개수
variable "instance_count" {
  description = "생성할 EC2 인스턴스 수 (환경별 조정)"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 5
    error_message = "인스턴스 수는 1~5 사이여야 합니다."
  }
}

# ==========================================
# 환경별 인스턴스 설정 (map(object) 패턴)
# ==========================================

# 환경별 기본 인스턴스 구성
# - 직접 instance_type/instance_count 변수 대신 이 맵을 사용할 수도 있음
variable "instance_config" {
  description = "환경별 인스턴스 설정 맵"
  type = map(object({
    instance_type  = string
    instance_count = number
  }))

  default = {
    dev = {
      instance_type  = "t2.micro"
      instance_count = 1
    }
    staging = {
      instance_type  = "t2.small"
      instance_count = 2
    }
    prod = {
      instance_type  = "t3.medium"
      instance_count = 3
    }
  }
}

# ==========================================
# 기능 플래그 (환경별 토글)
# ==========================================

# 백업 활성화 여부
variable "enable_backup" {
  description = "백업 태그 활성화 여부 (Prod에서는 필수)"
  type        = bool
  default     = false
}

# 모니터링 활성화 여부
variable "enable_monitoring" {
  description = "상세 모니터링 활성화 여부 (추가 비용 발생)"
  type        = bool
  default     = false
}

# ==========================================
# 보안 설정 변수
# ==========================================

# SSH 접근 허용 IP
variable "allowed_ssh_cidr_blocks" {
  description = "SSH 접근을 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "모든 항목이 올바른 CIDR 형식이어야 합니다."
  }
}

# HTTP 접근 허용 IP
variable "allowed_http_cidr_blocks" {
  description = "HTTP 접근을 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.allowed_http_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "모든 항목이 올바른 CIDR 형식이어야 합니다."
  }
}

# variables.tf
# 입력 변수 선언 파일
# - 코드의 재사용성과 유연성을 높이기 위해 변수 사용

# 기본 설정 변수 / 네트워크 설정 변수 / EC2 인스턴스 설정 변수 / 보안 설정 변수 / 추가 태그 ( 선택사항 ) / 기능 플래그 ( 선택사항 )

# ====================================================================================
# 기본 설정 변수
# - AWS 리전 변수 / 환경 변수 / 프로젝트 이름 변수
# ====================================================================================

# AWS 리전 변수
variable "aws_region" {
  description = "AWS 리소스를 생성할 리전 (예: ap-northeast-2는 서울)"
  type        = string
  default     = "ap-northeast-2"

  # 리전 값 검증 - 올바른 AWS 리전 형식인지 확인
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "유효한 AWS 리전 형식이어야 합니다 (예: ap-northeast-2)."
  }
}

# 환경 변수 (개발, 스테이징, 프로덕션 구분)
variable "environment" {
  description = "환경 구분 (dev, staging, prod)"
  type        = string
  default     = "dev"

  # 입력값 검증 - 지정된 값만 허용
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

# 프로젝트 이름 변수
variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
  default     = "terraform-basic"

  # 프로젝트 이름 검증 - 알파벳, 숫자, 하이픈만 허용
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "프로젝트 이름은 소문자, 숫자, 하이픈(-)만 사용 가능합니다."
  }
}

# ====================================================================================
# 네트워크 설정 변수
# - VPC CIDR 블록 / Public Subnet CIDR 블록 / 가용 영역
# ====================================================================================

# VPC CIDR 블록
variable "vpc_cidr" {
  description = "VPC의 CIDR 블록 (IP 주소 범위) - 10.0.0.0/16은 65,536개 IP 주소"
  type        = string
  default     = "10.0.0.0/16"

  # CIDR 형식 검증
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다 (예: 10.0.0.0/16)."
  }
}

# Public Subnet CIDR 블록
variable "public_subnet_cidr" {
  description = "Public Subnet의 CIDR 블록 - 10.0.1.0/24는 256개 IP 주소"
  type        = string
  default     = "10.0.1.0/24"

  # CIDR 형식 검증
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다 (예: 10.0.1.0/24)."
  }
}

# 가용 영역 (Availability Zone)
variable "availability_zone" {
  description = "Public Subnet을 생성할 가용 영역 (예: ap-northeast-2a)"
  type        = string
  default     = null  # null이면 리전의 첫 번째 AZ 자동 선택

  # AZ 형식 검증 (값이 있을 때만)
  validation {
    condition     = var.availability_zone == null || can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}[a-z]$", var.availability_zone))
    error_message = "유효한 가용 영역 형식이어야 합니다 (예: ap-northeast-2a)."
  }
}

# ====================================================================================
# EC2 인스턴스 설정 변수
# - 인스턴스 타입 / AMI ID / EC2 인스턴스 루트 볼륨 크기
# ====================================================================================

# 인스턴스 타입
variable "instance_type" {
  description = "EC2 인스턴스 타입 (t2.micro는 프리티어 사용 가능)"
  type        = string
  default     = "t2.micro"

  # 프리티어 인스턴스 타입만 허용 (비용 절감)
  validation {
    condition     = contains(["t2.micro", "t2.small", "t3.micro"], var.instance_type)
    error_message = "프리티어 또는 저비용 인스턴스 타입을 사용하세요 (t2.micro, t2.small, t3.micro)."
  }
}

# AMI ID (선택사항 - data source로 자동 조회하므로 보통 사용하지 않음)
variable "ami_id" {
  description = "사용할 AMI ID (비워두면 최신 Amazon Linux 2023 자동 선택)"
  type        = string
  default     = null
}

# EC2 인스턴스 루트 볼륨 크기
variable "root_volume_size" {
  description = "EC2 인스턴스 루트 볼륨 크기 (GB)"
  type        = number
  default     = 8  # 프리티어는 최대 30GB까지 무료

  # 볼륨 크기 검증
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 30
    error_message = "루트 볼륨 크기는 8GB에서 30GB 사이여야 합니다."
  }
}

# ====================================================================================
# 보안 설정 변수
# - SSH 접근 허용 IP 목록 / HTTP 접근 허용 IP 목록
# ====================================================================================
# SSH 접근 허용 IP 목록
variable "allowed_ssh_cidr_blocks" {
  description = "SSH 접근을 허용할 IP 주소 범위 (보안을 위해 특정 IP만 허용 권장)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 기본값은 모든 IP 허용 (프로덕션에서는 권장하지 않음)

  # CIDR 목록 검증
  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "모든 항목이 올바른 CIDR 형식이어야 합니다."
  }
}

# HTTP 접근 허용 IP 목록
variable "allowed_http_cidr_blocks" {
  description = "HTTP 접근을 허용할 IP 주소 범위"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 웹 서버이므로 모든 IP 허용

  # CIDR 목록 검증
  validation {
    condition     = alltrue([for cidr in var.allowed_http_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "모든 항목이 올바른 CIDR 형식이어야 합니다."
  }
}

# ====================================================================================
# 추가 태그 (선택사항)
# ====================================================================================

# 사용자 정의 태그
variable "additional_tags" {
  description = "리소스에 추가할 사용자 정의 태그"
  type        = map(string)
  default     = {}

  # 예시:
  # additional_tags = {
  #   Owner       = "TeamA"
  #   CostCenter  = "Engineering"
  #   Compliance  = "PCI-DSS"
  # }
}

# ====================================================================================
# 기능 플래그 (선택사항)
# ====================================================================================

# 상세 모니터링 활성화 여부
variable "enable_detailed_monitoring" {
  description = "EC2 인스턴스의 상세 모니터링 활성화 여부 (추가 비용 발생)"
  type        = bool
  default     = false
}

# EBS 최적화 활성화 여부
variable "enable_ebs_optimization" {
  description = "EC2 인스턴스의 EBS 최적화 활성화 여부"
  type        = bool
  default     = false
}
# ==========================================
# variables.tf - 프로덕션 입력 변수 정의
# ==========================================
#
# 이 파일의 역할:
#   프로덕션 레벨의 변수는 "무엇이든 될 수 있다"가 아니라
#   "허용된 값만 받아들인다"는 원칙으로 설계합니다.
#   모든 변수에 validation을 추가하여 실수를 사전에 방지합니다.
#
# 변수 설계 원칙:
#   1. 모든 변수에 description 작성 (문서화)
#   2. 가능한 모든 변수에 validation 추가 (안전장치)
#   3. 합리적인 default 값 설정 (사용 편의성)
#   4. type 명시 (타입 안전성)

# ==========================================
# 프로젝트 기본 설정
# ==========================================

variable "project_name" {
  description = "프로젝트 이름 - 모든 리소스 이름의 접두사로 사용됩니다"
  type        = string
  default     = "tf-study"

  # 리소스 이름에 사용되므로 특수문자 제한
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.project_name))
    error_message = "프로젝트 이름은 소문자로 시작하고, 소문자/숫자/하이픈만 사용 가능합니다."
  }
}

variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string

  # 허용된 환경만 사용 가능
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "aws_region" {
  description = "AWS 리전 - 리소스가 생성될 지역"
  type        = string
  default     = "ap-northeast-2" # 서울 리전

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "올바른 AWS 리전 형식이 아닙니다. (예: ap-northeast-2)"
  }
}

# ==========================================
# 네트워크 설정
# ==========================================

variable "vpc_cidr" {
  description = "VPC의 CIDR 블록 - 환경별로 다른 대역을 사용합니다"
  type        = string
  default     = "10.0.0.0/16"

  # CIDR 형식 검증
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "올바른 CIDR 형식이 아닙니다. (예: 10.0.0.0/16)"
  }
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록 - 가용영역별로 하나씩"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  # 최소 1개의 서브넷 필요
  validation {
    condition     = length(var.public_subnet_cidrs) >= 1
    error_message = "최소 1개의 퍼블릭 서브넷이 필요합니다."
  }
}

variable "availability_zones" {
  description = "사용할 가용영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# ==========================================
# EC2 인스턴스 설정
# ==========================================

variable "instance_type" {
  description = "EC2 인스턴스 타입 - 환경별로 적절한 사양을 선택합니다"
  type        = string
  default     = "t2.micro"

  # 프로덕션에서 허용하는 인스턴스 타입 제한
  # 비용 폭탄 방지를 위해 허용 목록을 관리합니다
  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium", "t3.large"
    ], var.instance_type)
    error_message = "허용되지 않는 인스턴스 타입입니다. t2.micro ~ t3.large 범위에서 선택하세요."
  }
}

variable "instance_count" {
  description = "생성할 EC2 인스턴스 수"
  type        = number
  default     = 1

  # 비용 제어를 위한 상한선
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "인스턴스 수는 1~10 사이여야 합니다."
  }
}

# ==========================================
# 보안 설정
# ==========================================

variable "allowed_ssh_cidrs" {
  description = "SSH 접근을 허용할 CIDR 목록 - 프로덕션에서는 VPN/사무실 IP만 허용"
  type        = list(string)
  default     = [] # 기본값: SSH 차단 (보안 강화)

  # 0.0.0.0/0 (전체 개방)이 포함되면 경고
  validation {
    condition     = !contains(var.allowed_ssh_cidrs, "0.0.0.0/0")
    error_message = "SSH를 0.0.0.0/0 (전체)에 개방하면 안 됩니다! 특정 IP만 허용하세요."
  }
}

variable "enable_detailed_monitoring" {
  description = "EC2 상세 모니터링 활성화 여부 (1분 간격, 추가 비용 발생)"
  type        = bool
  default     = false
}

# ==========================================
# 태그 설정
# ==========================================

variable "additional_tags" {
  description = "추가 태그 맵 - 팀별/서비스별 커스텀 태그를 추가할 수 있습니다"
  type        = map(string)
  default     = {}
}

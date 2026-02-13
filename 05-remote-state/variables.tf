# ==========================================
# variables.tf - 입력 변수 정의
# ==========================================
#
# 이 파일은 Terraform 코드에서 사용하는 변수를 선언합니다.
# 변수를 사용하면 동일한 코드로 다양한 환경을 구성할 수 있습니다.
#
# 변수 값 설정 우선순위 (높은 순):
#   1. -var 플래그 (terraform apply -var="환경=prod")
#   2. -var-file 플래그 (terraform apply -var-file=prod.tfvars)
#   3. terraform.tfvars 파일 (자동 로드)
#   4. 환경변수 (TF_VAR_변수명)
#   5. default 값

# ==========================================
# 기본 설정 변수
# ==========================================

variable "aws_region" {
  description = "AWS 리소스를 생성할 리전 (서울: ap-northeast-2)"
  type        = string
  default     = "ap-northeast-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "유효한 AWS 리전 형식이어야 합니다 (예: ap-northeast-2)."
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
  description = "프로젝트 이름 (리소스 이름에 접두사로 사용)"
  type        = string
  default     = "remote-state"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "프로젝트 이름은 소문자, 숫자, 하이픈(-)만 사용 가능합니다."
  }
}

# ==========================================
# 네트워크 설정 변수
# ==========================================

variable "vpc_cidr" {
  description = "VPC의 CIDR 블록 (IP 주소 범위)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다 (예: 10.0.0.0/16)."
  }
}

variable "public_subnet_cidr" {
  description = "Public Subnet의 CIDR 블록"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다 (예: 10.0.1.0/24)."
  }
}

# ==========================================
# EC2 설정 변수
# ==========================================

variable "instance_type" {
  description = "EC2 인스턴스 타입 (t2.micro는 프리티어 사용 가능)"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t2.small", "t3.micro"], var.instance_type)
    error_message = "프리티어 인스턴스 타입을 사용하세요: t2.micro, t2.small, t3.micro"
  }
}

# 입력 변수 선언 (LocalStack용)

# ====================================================================================
# 기본 설정 변수
# ====================================================================================

variable "aws_region" {
  description = "AWS 리전 (LocalStack에서는 실제 리전이 아님)"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "환경 구분"
  type        = string
  default     = "localstack"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "terraform-localstack"
}

# ====================================================================================
# 네트워크 설정 변수
# ====================================================================================
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

# ====================================================================================
# EC2 인스턴스 설정 변수
# ====================================================================================
variable "instance_type" {
  description = "EC2 인스턴스 타입 (LocalStack에서는 실제로 생성되지 않음)"
  type        = string
  default     = "t2.micro"
}
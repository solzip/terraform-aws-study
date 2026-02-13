# ==========================================
# variables.tf - 입력 변수 정의
# ==========================================
#
# CI/CD 환경에서 변수 전달 방법:
#   1. terraform.tfvars 파일 (Git에 포함 X)
#   2. -var 플래그: terraform plan -var="environment=prod"
#   3. -var-file 플래그: terraform plan -var-file="prod.tfvars"
#   4. 환경변수: TF_VAR_environment=prod
#   5. GitHub Actions에서는 주로 -var-file 또는 환경변수 사용

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "tf-cicd"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "프로젝트 이름은 소문자로 시작하고, 소문자/숫자/하이픈만 사용 가능합니다."
  }
}

variable "environment" {
  description = "배포 환경 (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

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

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"
}

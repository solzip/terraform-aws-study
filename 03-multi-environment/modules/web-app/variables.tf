# modules/web-app/variables.tf
# 웹 앱 모듈의 입력 변수

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "인스턴스를 배포할 Subnet ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "사용할 AMI ID"
  type        = string
}

variable "is_production" {
  description = "프로덕션 환경 여부"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "공통 태그 맵"
  type        = map(string)
  default     = {}
}

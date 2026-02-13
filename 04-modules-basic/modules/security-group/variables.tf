# modules/security-group/variables.tf
# Security Group 모듈 입력 변수

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 구분 (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "Security Group을 생성할 VPC ID"
  type        = string
}

variable "allowed_ssh_cidr_blocks" {
  description = "SSH 접근을 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "모든 항목이 올바른 CIDR 형식이어야 합니다."
  }
}

variable "allowed_http_cidr_blocks" {
  description = "HTTP 접근을 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.allowed_http_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "모든 항목이 올바른 CIDR 형식이어야 합니다."
  }
}

variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}

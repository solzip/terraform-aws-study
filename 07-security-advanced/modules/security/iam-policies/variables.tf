# ==========================================
# modules/security/iam-policies/variables.tf
# ==========================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev/staging/prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전 - 조건부 정책에서 리전 제한에 사용"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}

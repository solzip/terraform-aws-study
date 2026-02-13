# ==========================================
# modules/secrets/variables.tf - Secrets Manager 모듈 입력 변수
# ==========================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 구분"
  type        = string
}

variable "kms_key_arn" {
  description = "Secret 암호화에 사용할 KMS 키 ARN"
  type        = string
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

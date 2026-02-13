# ==========================================
# modules/kms/variables.tf - KMS 모듈 입력 변수
# ==========================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 구분"
  type        = string
}

variable "deletion_window_in_days" {
  description = "KMS 키 삭제 대기 기간 (일)"
  type        = number
  default     = 7
}

variable "enable_key_rotation" {
  description = "KMS 키 자동 교체 활성화 여부"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

# ==========================================
# modules/monitoring/sns/variables.tf
# ==========================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "alarm_email" {
  description = "알림을 받을 이메일 주소 (빈 문자열이면 구독 생성 안함)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

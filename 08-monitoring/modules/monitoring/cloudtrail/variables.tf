# ==========================================
# modules/monitoring/cloudtrail/variables.tf
# ==========================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "retention_days" {
  description = "CloudTrail 로그 보관 기간 (일)"
  type        = number
  default     = 7
}

variable "critical_topic_arn" {
  description = "긴급 알림 SNS Topic ARN (루트 로그인 알림용)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

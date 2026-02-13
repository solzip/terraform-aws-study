# ==========================================
# modules/security/kms/variables.tf
# ==========================================

variable "project_name" {
  description = "프로젝트 이름 - KMS 키 이름에 접두사로 사용"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev/staging/prod)"
  type        = string
}

variable "deletion_window_in_days" {
  description = <<-EOT
    KMS 키 삭제 대기 기간 (일)

    키를 삭제 예약하면 이 기간 동안 삭제를 취소할 수 있습니다.
    기간이 지나면 키가 완전히 삭제되며, 해당 키로 암호화된
    모든 데이터에 접근할 수 없게 됩니다.
  EOT
  type        = number
  default     = 7
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}

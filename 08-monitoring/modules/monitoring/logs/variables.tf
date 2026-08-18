# ==========================================
# modules/monitoring/logs/variables.tf
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
  description = <<-EOT
    로그 보관 기간 (일)

    이 기간이 지나면 로그 이벤트가 자동으로 삭제됩니다.
    0을 지정하면 영구 보관합니다 (비용 주의).

    학습용: 7일, 프로덕션: 90일 이상 권장
  EOT
  type        = number
  default     = 7

  # CloudWatch Logs는 아무 숫자나 받지 않습니다.
  # 정해진 값 목록에 없는 값을 넣으면 apply 단계에서 에러가 발생하므로
  # plan 이전에 미리 걸러냅니다.
  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.retention_days
    )
    error_message = "retention_days는 CloudWatch Logs가 허용하는 값이어야 합니다 (0, 1, 3, 5, 7, 14, 30, 60, 90, 120, ... 3653)."
  }
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

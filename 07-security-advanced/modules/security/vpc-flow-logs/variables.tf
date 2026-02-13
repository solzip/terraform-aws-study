# ==========================================
# modules/security/vpc-flow-logs/variables.tf
# ==========================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev/staging/prod)"
  type        = string
}

variable "vpc_id" {
  description = <<-EOT
    Flow Logs를 활성화할 VPC의 ID

    이 VPC 내 모든 네트워크 인터페이스(ENI)의
    트래픽이 기록됩니다.
  EOT
  type        = string
}

variable "retention_days" {
  description = <<-EOT
    CloudWatch Logs 보관 기간 (일)

    허용 값: 0(무기한), 1, 3, 5, 7, 14, 30, 60, 90,
             120, 150, 180, 365 등

    학습용: 7일 권장 (비용 절감)
    프로덕션: 90일 이상 권장 (규정 준수)
  EOT
  type        = number
  default     = 7
}

variable "kms_key_arn" {
  description = "CloudWatch Logs 암호화에 사용할 KMS 키 ARN (선택)"
  type        = string
  default     = ""
}

variable "alarm_sns_topic_arn" {
  description = <<-EOT
    거부된 트래픽 알림을 전송할 SNS 토픽 ARN

    빈 문자열("")이면 알림을 설정하지 않습니다.
    SNS 토픽을 연결하면 이메일, Slack 등으로 알림을 받을 수 있습니다.
  EOT
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}

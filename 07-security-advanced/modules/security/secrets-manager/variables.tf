# ==========================================
# modules/security/secrets-manager/variables.tf
# ==========================================
#
# Secrets Manager 모듈의 입력 변수입니다.
# 이 모듈을 호출하는 루트 모듈에서 값을 전달받습니다.

variable "project_name" {
  description = "프로젝트 이름 - Secret 이름의 접두사로 사용"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev/staging/prod)"
  type        = string
}

variable "kms_key_arn" {
  description = <<-EOT
    Secret을 암호화할 KMS 키의 ARN

    Secrets Manager는 기본적으로 AWS 관리형 키로 암호화하지만,
    고객 관리형 키(CMK)를 지정하면 더 세밀한 접근 제어가 가능합니다.
  EOT
  type        = string
}

variable "rotation_lambda_arn" {
  description = <<-EOT
    Secret 자동 로테이션을 수행할 Lambda 함수의 ARN

    이 Lambda 함수가 주기적으로 호출되어
    새로운 비밀번호를 생성하고 Secret을 업데이트합니다.
  EOT
  type        = string
  default     = ""
}

variable "rotation_days" {
  description = "Secret 자동 로테이션 주기 (일)"
  type        = number
  default     = 30
}

variable "enable_rotation" {
  description = <<-EOT
    Secret 자동 로테이션 활성화 여부

    true로 설정하면 rotation_days 주기로
    Lambda 함수가 자동 호출되어 비밀번호를 교체합니다.

    주의: rotation_lambda_arn이 유효해야 합니다.
  EOT
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default     = {}
}

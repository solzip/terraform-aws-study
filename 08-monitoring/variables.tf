# ==========================================
# variables.tf - 입력 변수 정의
# ==========================================

# ==========================================
# 기본 설정
# ==========================================

variable "project_name" {
  description = "프로젝트 이름 - 모든 리소스 이름의 접두사"
  type        = string
  default     = "tf-monitoring"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "프로젝트 이름은 소문자로 시작하고, 소문자/숫자/하이픈만 사용 가능합니다."
  }
}

variable "environment" {
  description = "배포 환경 (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

# ==========================================
# 네트워크 설정
# ==========================================

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR 블록"
  type        = string
  default     = "10.0.1.0/24"
}

# ==========================================
# EC2 설정
# ==========================================

variable "instance_type" {
  description = "EC2 인스턴스 타입 (t2.micro = 프리티어)"
  type        = string
  default     = "t2.micro"
}

# ==========================================
# 모니터링 설정
# ==========================================

variable "alarm_email" {
  description = <<-EOT
    알림을 받을 이메일 주소

    SNS 구독 확인 이메일이 발송됩니다.
    이메일의 "Confirm subscription" 링크를 클릭해야
    실제 알림을 받을 수 있습니다.

    빈 문자열("")이면 이메일 구독을 생성하지 않습니다.
  EOT
  type        = string
  default     = ""
}

variable "cpu_alarm_threshold" {
  description = <<-EOT
    CPU 사용률 알람 임계값 (%)

    이 값을 초과하면 알람이 발생합니다.
    예: 80 = CPU 사용률이 80%를 초과하면 알림

    권장값:
      - 개발: 90%
      - 프로덕션: 70~80%
  EOT
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "CPU 알람 임계값은 1~100 사이여야 합니다."
  }
}

variable "log_retention_days" {
  description = <<-EOT
    CloudWatch Logs 보관 기간 (일)

    이 기간이 지나면 로그가 자동 삭제됩니다.
    학습용: 7일, 프로덕션: 90일 이상 권장
  EOT
  type        = number
  default     = 7
}

variable "enable_cloudtrail" {
  description = <<-EOT
    CloudTrail 활성화 여부

    CloudTrail은 모든 AWS API 호출을 기록합니다.
    관리 이벤트는 무료이지만, 데이터 이벤트는 유료입니다.
  EOT
  type        = bool
  default     = true
}

variable "enable_dashboard" {
  description = <<-EOT
    CloudWatch Dashboard 활성화 여부

    3개까지 무료, 이후 대시보드당 $3/월
  EOT
  type        = bool
  default     = true
}

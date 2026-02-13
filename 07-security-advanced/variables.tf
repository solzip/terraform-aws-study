# ==========================================
# variables.tf - 입력 변수 정의
# ==========================================
#
# 이 파일의 역할:
#   Terraform 코드에서 사용하는 모든 변수를 선언합니다.
#   변수를 사용하면 동일한 코드를 다른 환경(dev/staging/prod)에서
#   재사용할 수 있습니다.
#
# 변수 적용 우선순위 (높은 순):
#   1. -var 플래그 (커맨드 라인)
#   2. -var-file 플래그
#   3. terraform.tfvars 파일
#   4. *.auto.tfvars 파일
#   5. 환경변수 (TF_VAR_xxx)
#   6. default 값

# ==========================================
# 기본 설정
# ==========================================

variable "project_name" {
  description = "프로젝트 이름 - 모든 리소스 이름에 접두사로 사용"
  type        = string
  default     = "tf-security-adv"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "프로젝트 이름은 소문자로 시작하고, 소문자/숫자/하이픈만 사용할 수 있습니다."
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
  description = "AWS 리전 - 리소스가 생성될 지역"
  type        = string
  default     = "ap-northeast-2" # 서울 리전

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "올바른 AWS 리전 형식이어야 합니다 (예: ap-northeast-2)."
  }
}

# ==========================================
# 네트워크 설정
# ==========================================

variable "vpc_cidr" {
  description = <<-EOT
    VPC의 CIDR 블록 (IP 주소 범위)

    CIDR 표기법:
      10.0.0.0/16 = 10.0.0.0 ~ 10.0.255.255 (65,536개 IP)

    VPC Flow Logs에서 이 범위의 트래픽이 기록됩니다.
  EOT
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public Subnet의 CIDR 블록"
  type        = string
  default     = "10.0.1.0/24" # 256개 IP
}

# ==========================================
# EC2 설정
# ==========================================

variable "instance_type" {
  description = <<-EOT
    EC2 인스턴스 타입

    학습 환경 권장:
      - t2.micro : 프리티어 (1 vCPU, 1GB RAM)
      - t3.micro : 성능 개선 (1 vCPU, 1GB RAM)

    프로덕션 환경:
      - t3.small 이상 권장
  EOT
  type        = string
  default     = "t2.micro"
}

# ==========================================
# 보안 설정
# ==========================================

variable "allowed_ssh_cidr_blocks" {
  description = <<-EOT
    SSH 접속을 허용할 IP 주소 범위 목록

    보안 모범 사례:
      - 프로덕션: 사무실/VPN IP만 허용 (예: ["203.0.113.0/24"])
      - 학습용: 전체 허용 (["0.0.0.0/0"]) - 주의 필요!

    여러 IP 대역을 허용하려면:
      ["203.0.113.0/24", "198.51.100.0/24"]
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_guardduty" {
  description = <<-EOT
    GuardDuty 활성화 여부

    GuardDuty란?
      AWS의 위협 탐지 서비스로, 악의적 활동이나
      비정상적인 행동을 자동으로 감지합니다.

    비용: 30일 무료 평가 → 이후 분석한 이벤트 수에 따라 과금
    학습 후 반드시 비활성화하세요!
  EOT
  type        = bool
  default     = true
}

variable "enable_config_rules" {
  description = <<-EOT
    AWS Config Rules 활성화 여부

    AWS Config란?
      AWS 리소스의 구성 변경을 기록하고,
      정의된 규칙에 따라 규정 준수 여부를 평가합니다.

    비용: 규칙 평가당 ~$0.001
  EOT
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = <<-EOT
    Security Hub 활성화 여부

    Security Hub란?
      GuardDuty, Config, Inspector 등 여러 보안 서비스의
      결과를 하나의 대시보드에서 통합 관리합니다.

    비용: 30일 무료 평가 → 이후 검사 건수에 따라 과금
  EOT
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = <<-EOT
    VPC Flow Logs 활성화 여부

    VPC Flow Logs란?
      VPC 내 네트워크 인터페이스로 들어오고 나가는
      IP 트래픽 정보를 캡처합니다.

    용도:
      - 보안 모니터링 (비정상 트래픽 감지)
      - 네트워크 문제 진단
      - 규정 준수 감사
  EOT
  type        = bool
  default     = true
}

variable "secret_rotation_days" {
  description = <<-EOT
    Secret 자동 로테이션 주기 (일)

    권장 주기:
      - 개발 환경: 90일
      - 스테이징: 60일
      - 프로덕션: 30일

    더 자주 교체할수록 보안은 강화되지만,
    애플리케이션이 새 비밀번호에 적응해야 합니다.
  EOT
  type        = number
  default     = 30

  validation {
    condition     = var.secret_rotation_days >= 1 && var.secret_rotation_days <= 365
    error_message = "로테이션 주기는 1일에서 365일 사이여야 합니다."
  }
}

variable "flow_log_retention_days" {
  description = <<-EOT
    VPC Flow Logs 보관 기간 (일)

    CloudWatch Logs에 저장되는 플로우 로그의 보관 기간입니다.
    오래 보관할수록 비용이 증가하지만, 보안 감사에 유용합니다.

    권장:
      - 학습용: 7일
      - 프로덕션: 90일 이상
  EOT
  type        = number
  default     = 7
}

variable "kms_deletion_window_days" {
  description = <<-EOT
    KMS 키 삭제 대기 기간 (일)

    KMS 키를 삭제하면 해당 키로 암호화된 모든 데이터에
    접근할 수 없게 됩니다! 실수로 삭제하는 것을 방지하기 위해
    대기 기간을 설정합니다.

    범위: 7일 ~ 30일
    학습용: 7일 (최소값)
    프로덕션: 30일 (최대값) 권장
  EOT
  type        = number
  default     = 7

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "KMS 키 삭제 대기 기간은 7일에서 30일 사이여야 합니다."
  }
}

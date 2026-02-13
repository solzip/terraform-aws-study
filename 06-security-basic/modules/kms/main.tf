# ==========================================
# modules/kms/main.tf - KMS 키 관리 모듈
# ==========================================
#
# AWS KMS (Key Management Service)란?
# - AWS에서 제공하는 암호화 키 관리 서비스
# - 데이터 암호화/복호화에 사용되는 "키"를 생성하고 관리
# - S3, EBS, RDS, Secrets Manager 등 다양한 서비스와 연동
#
# KMS 키의 종류:
#   1. AWS 관리형 키 (aws/s3, aws/ebs 등)
#      - AWS가 자동 생성/관리, 무료
#      - 세밀한 제어 불가
#
#   2. 고객 관리형 키 (CMK - Customer Managed Key)
#      - 사용자가 직접 생성/관리 (이 모듈에서 생성)
#      - 키 정책, 교체 주기 등 세밀한 제어 가능
#      - 월 $1 + API 호출 비용
#
# 키 교체 (Key Rotation):
#   - enable_key_rotation = true 로 설정하면
#   - AWS가 1년마다 자동으로 새 키 재료를 생성
#   - 기존 키로 암호화된 데이터는 여전히 복호화 가능
#   - 보안 모범 사례!

# ==========================================
# 현재 AWS 계정 정보 조회
# ==========================================
#
# KMS 키 정책에서 현재 계정의 루트 사용자를
# 키 관리자로 설정하기 위해 계정 ID가 필요합니다.

data "aws_caller_identity" "current" {}

# ==========================================
# KMS Key - 고객 관리형 암호화 키
# ==========================================

resource "aws_kms_key" "main" {
  # 키 설명 - 무엇을 위한 키인지 명시
  description = "${var.project_name}-${var.environment} encryption key"

  # 키 삭제 대기 기간 (일)
  # KMS 키를 삭제 요청하면 즉시 삭제되지 않고
  # 이 기간 동안 "삭제 예정" 상태가 됩니다.
  # 실수로 삭제한 경우 이 기간 내에 복구할 수 있습니다.
  # 최소 7일 ~ 최대 30일
  deletion_window_in_days = var.deletion_window_in_days

  # 자동 키 교체 활성화
  # true로 설정하면 AWS가 1년마다 자동으로 키 재료를 교체합니다.
  # 기존 키로 암호화된 데이터는 계속 복호화할 수 있으므로
  # 서비스 중단 없이 키를 교체할 수 있습니다.
  enable_key_rotation = var.enable_key_rotation

  # 키 정책 (Key Policy)
  # 이 키에 대한 접근 권한을 정의합니다.
  # IAM Policy와 함께 작동하여 이중 인증 역할을 합니다.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 루트 사용자에게 모든 KMS 권한 부여
        # 이것이 없으면 키를 관리할 수 없게 될 수 있습니다!
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-kms-key"
  })
}

# ==========================================
# KMS Alias - 키에 읽기 쉬운 이름 부여
# ==========================================
#
# KMS 키의 기본 ID는 UUID 형태 (예: 12345678-abcd-efgh-1234-567890abcdef)
# 읽기 어려우므로 Alias를 만들어 쉬운 이름으로 참조할 수 있습니다.
#
# 사용 예:
#   aws kms encrypt --key-id alias/my-project-dev-key --plaintext "secret"

resource "aws_kms_alias" "main" {
  # Alias 이름 (반드시 "alias/"로 시작해야 함)
  name = "alias/${var.project_name}-${var.environment}-key"

  # 이 Alias가 가리킬 KMS 키
  target_key_id = aws_kms_key.main.key_id
}

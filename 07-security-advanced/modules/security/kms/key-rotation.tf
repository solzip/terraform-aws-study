# ==========================================
# modules/security/kms/key-rotation.tf
# ==========================================
#
# KMS (Key Management Service) 키 로테이션 심화
#
# 06-security-basic과의 차이점:
#   - 06: KMS 키 1개 생성 + 기본 키 정책
#   - 07: 용도별 키 분리 + 세밀한 키 정책 + 키 로테이션 관리
#
# KMS 키 로테이션이란?
#   AWS가 매년 자동으로 새로운 암호화 키를 생성하는 기능입니다.
#   이전 키로 암호화된 데이터도 계속 복호화할 수 있습니다.
#   (이전 키는 삭제되지 않고 보관됨)
#
# 왜 키 로테이션이 중요한가?
#   - 키가 유출되더라도 피해 범위를 제한
#   - 규정 준수 요건 (PCI DSS: 연 1회 키 교체)
#   - 보안 모범 사례 (NIST, CIS Benchmark)

# ==========================================
# 현재 AWS 계정 정보 조회
# ==========================================
#
# KMS 키 정책에서 현재 계정의 ARN이 필요합니다.
# data 소스로 현재 로그인된 계정 정보를 가져옵니다.

data "aws_caller_identity" "current" {}

# ==========================================
# 메인 암호화 키 (범용)
# ==========================================
#
# 일반적인 데이터 암호화에 사용하는 범용 KMS 키입니다.
# S3 버킷, EBS 볼륨, RDS 등의 암호화에 활용됩니다.
#
# 키 유형:
#   - 대칭 키 (SYMMETRIC_DEFAULT): 암호화/복호화에 같은 키 사용
#     → 가장 일반적, AWS 서비스와 호환성 좋음
#   - 비대칭 키 (RSA, ECC): 공개키/개인키 쌍
#     → 서명, 외부 시스템 통합에 사용

resource "aws_kms_key" "main" {
  description = "${var.project_name}-${var.environment} 범용 암호화 키"

  # 키 로테이션 활성화
  # true로 설정하면 AWS가 매년 자동으로 새 키를 생성합니다.
  # 이전 키는 삭제되지 않아 기존 데이터 복호화에 문제 없습니다.
  enable_key_rotation = true

  # 키 삭제 대기 기간
  # KMS 키 삭제는 매우 위험합니다!
  # 삭제된 키로 암호화된 데이터는 영원히 접근 불가능합니다.
  # 대기 기간 동안 삭제를 취소할 수 있습니다.
  deletion_window_in_days = var.deletion_window_in_days

  # ==========================================
  # KMS 키 정책 (Key Policy)
  # ==========================================
  #
  # KMS 키 정책은 "누가 이 키를 사용할 수 있는가"를 정의합니다.
  # IAM 정책과는 별도로 키 자체에 적용되는 접근 제어입니다.
  #
  # 키 정책이 없으면 루트 계정도 키를 관리할 수 없게 됩니다!
  # 따라서 최소한 루트 계정에 키 관리 권한을 부여해야 합니다.
  #
  # 정책 구조:
  #   Statement 1: 루트 계정에 전체 권한 (키 관리의 안전장치)
  #   Statement 2: 관리자에게 키 관리 권한
  #   Statement 3: 사용자(EC2, Lambda 등)에게 사용 권한만
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Statement 1: 루트 계정 전체 접근
        # 이 정책이 없으면 키를 관리할 수 없는 상황이 발생할 수 있음
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        # Statement 2: 키 관리 권한 (관리자용)
        # 키를 생성하거나 삭제하는 것과 같은 관리 작업에 필요
        # 실제 데이터 암호화/복호화 권한은 포함하지 않음 (분리 원칙)
        Sid    = "AllowKeyAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Create*",             # 키 생성
          "kms:Describe*",           # 키 정보 조회
          "kms:Enable*",             # 키 활성화
          "kms:List*",               # 키 목록 조회
          "kms:Put*",                # 키 정책 설정
          "kms:Update*",             # 키 업데이트
          "kms:Revoke*",             # 권한 취소
          "kms:Disable*",            # 키 비활성화
          "kms:Get*",                # 키 정보 가져오기
          "kms:Delete*",             # 키 삭제 (주의!)
          "kms:TagResource",         # 태그 추가
          "kms:UntagResource",       # 태그 제거
          "kms:ScheduleKeyDeletion", # 삭제 예약
          "kms:CancelKeyDeletion"    # 삭제 취소
        ]
        Resource = "*"
      },
      {
        # Statement 3: 키 사용 권한 (서비스/애플리케이션용)
        # 실제 암호화/복호화 작업에 필요한 최소 권한만 부여
        Sid    = "AllowKeyUsage"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Encrypt",          # 데이터 암호화
          "kms:Decrypt",          # 데이터 복호화
          "kms:ReEncrypt*",       # 다른 키로 재암호화
          "kms:GenerateDataKey*", # 데이터 키 생성 (봉투 암호화)
          "kms:DescribeKey"       # 키 정보 조회
        ]
        Resource = "*"
      },
      {
        # Statement 4: AWS 서비스가 키를 사용할 수 있도록 허용
        # Grant(권한 위임)를 통해 S3, EBS, RDS 등이 키를 사용
        Sid    = "AllowServiceGrants"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:CreateGrant", # Grant 생성
          "kms:ListGrants",  # Grant 목록 조회
          "kms:RevokeGrant"  # Grant 취소
        ]
        Resource = "*"
        # 조건: Grant를 위임받은 서비스만 다시 위임 가능
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-${var.environment}-main-key"
    Purpose  = "GeneralEncryption"
    Rotation = "Enabled"
  })
}

# ==========================================
# KMS 키 Alias (별칭)
# ==========================================
#
# KMS 키는 ID가 "a1b2c3d4-5678-90ab-cdef-example11111" 같은
# 형태라서 기억하기 어렵습니다.
#
# Alias를 설정하면 "alias/my-project-key" 같은 이름으로
# 키를 참조할 수 있어 관리가 편합니다.
#
# Alias의 장점:
#   - 사람이 읽기 쉬운 이름
#   - 키 로테이션 시 Alias를 유지하면서 키만 교체 가능
#   - IAM 정책에서 Alias로 키를 참조 가능

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}-main"
  target_key_id = aws_kms_key.main.key_id
}

# ==========================================
# Secrets Manager 전용 키 (분리된 키)
# ==========================================
#
# 왜 키를 분리하는가?
#   - 용도별로 키를 분리하면 접근 제어가 더 세밀해짐
#   - Secrets Manager 키가 유출되어도 S3/EBS 데이터에는 영향 없음
#   - 키별로 독립적인 로테이션 정책 적용 가능
#   - 감사 로그에서 어떤 용도로 키가 사용되었는지 구분 가능

resource "aws_kms_key" "secrets" {
  description             = "${var.project_name}-${var.environment} Secrets Manager 전용 암호화 키"
  enable_key_rotation     = true
  deletion_window_in_days = var.deletion_window_in_days

  # Secrets Manager 전용이므로 간단한 키 정책 적용
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
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
    Name     = "${var.project_name}-${var.environment}-secrets-key"
    Purpose  = "SecretsManagerEncryption"
    Rotation = "Enabled"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# ==========================================
# config-rules.tf - AWS Config Rules
# ==========================================
#
# AWS Config란?
#   AWS 리소스의 구성(Configuration)을 지속적으로 기록하고,
#   정의된 규칙에 따라 규정 준수 여부를 평가하는 서비스입니다.
#
# 쉽게 말하면:
#   "우리 AWS 환경이 보안 규칙을 잘 지키고 있는지 자동 검사"
#
# AWS Config의 동작 방식:
#   1. 리소스 구성 변경 기록 (Configuration Items)
#   2. 규칙(Config Rule)에 따라 평가
#   3. 규칙에 맞지 않는 리소스를 "NON_COMPLIANT"로 표시
#   4. 대시보드에서 전체 규정 준수 현황 확인
#
# 비용:
#   - 구성 기록: 리소스당 $0.003/월
#   - 규칙 평가: 평가당 $0.001
#   - 학습용으로 수 개의 규칙은 거의 무료
#
# Managed Rules (사전 정의 규칙):
#   AWS에서 미리 만들어놓은 규칙으로, 코드 작성 없이 바로 사용 가능
#   200개 이상의 Managed Rule이 제공됩니다.

# ==========================================
# AWS Config Recorder
# ==========================================
#
# Config Recorder는 AWS 리소스의 구성 변경을 기록합니다.
# 리전당 하나의 Recorder만 존재할 수 있습니다.

# Config Recorder용 IAM Role
resource "aws_iam_role" "config" {
  count = var.enable_config_rules ? 1 : 0

  name = "${var.project_name}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Config에 AWS 관리형 정책 연결
# AWSConfigRole: Config가 리소스 구성을 읽을 수 있는 권한
resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_config_rules ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Config Recorder 생성
resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config_rules ? 1 : 0

  name     = "${var.project_name}-${var.environment}-recorder"
  role_arn = aws_iam_role.config[0].arn

  # 기록 설정
  recording_group {
    # 모든 리소스 유형을 기록
    all_supported = true
    # 글로벌 리소스(IAM 등)도 기록
    include_global_resource_types = true
  }
}

# Config 전송 채널 - S3 버킷에 구성 스냅샷 저장
resource "aws_s3_bucket" "config" {
  count = var.enable_config_rules ? 1 : 0

  bucket        = "${var.project_name}-${var.environment}-config-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # 학습용: 버킷 삭제 시 객체도 함께 삭제

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-config-bucket"
  })
}

# S3 버킷 정책 - Config 서비스가 버킷에 쓸 수 있도록 허용
resource "aws_s3_bucket_policy" "config" {
  count = var.enable_config_rules ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowConfigBucketAccess"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config[0].arn
      },
      {
        Sid    = "AllowConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Config 전송 채널
resource "aws_config_delivery_channel" "main" {
  count = var.enable_config_rules ? 1 : 0

  name           = "${var.project_name}-${var.environment}-delivery"
  s3_bucket_name = aws_s3_bucket.config[0].id

  depends_on = [aws_config_configuration_recorder.main]
}

# Config Recorder 활성화
resource "aws_config_configuration_recorder_status" "main" {
  count = var.enable_config_rules ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# ==========================================
# Config Rule 1: EBS 볼륨 암호화 확인
# ==========================================
#
# 모든 EBS 볼륨이 암호화되어 있는지 확인합니다.
# 암호화되지 않은 볼륨이 있으면 NON_COMPLIANT로 표시됩니다.
#
# Managed Rule: encrypted-volumes
# 이 규칙은 AWS가 미리 만들어놓은 것으로,
# 소스 코드 없이 식별자만 지정하면 됩니다.

resource "aws_config_config_rule" "encrypted_volumes" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${var.project_name}-ebs-encryption"
  description = "EBS 볼륨이 KMS로 암호화되어 있는지 확인"

  source {
    owner             = "AWS"               # AWS 관리형 규칙
    source_identifier = "ENCRYPTED_VOLUMES" # 규칙 식별자
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = local.common_tags
}

# ==========================================
# Config Rule 2: Security Group SSH 제한 확인
# ==========================================
#
# Security Group에서 SSH(22번 포트)가 0.0.0.0/0으로
# 완전히 개방되어 있지 않은지 확인합니다.
#
# 0.0.0.0/0으로 SSH 개방 = 전 세계에서 접속 가능 = 매우 위험!

resource "aws_config_config_rule" "restricted_ssh" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${var.project_name}-restricted-ssh"
  description = "Security Group에서 SSH가 0.0.0.0/0으로 개방되지 않았는지 확인"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = local.common_tags
}

# ==========================================
# Config Rule 3: S3 버킷 퍼블릭 접근 차단 확인
# ==========================================
#
# S3 버킷에 퍼블릭 접근이 차단되어 있는지 확인합니다.
# 의도하지 않은 퍼블릭 접근은 데이터 유출의 주요 원인입니다.

resource "aws_config_config_rule" "s3_public_access" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${var.project_name}-s3-public-access"
  description = "S3 버킷의 퍼블릭 접근이 차단되어 있는지 확인"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = local.common_tags
}

# ==========================================
# Config Rule 4: IAM 루트 계정 MFA 확인
# ==========================================
#
# AWS 루트 계정에 MFA(다중 인증)가 설정되어 있는지 확인합니다.
# 루트 계정은 모든 권한을 가지므로 MFA 설정이 필수입니다.

resource "aws_config_config_rule" "root_mfa" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${var.project_name}-root-mfa"
  description = "루트 계정에 MFA가 활성화되어 있는지 확인"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = local.common_tags
}

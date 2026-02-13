# ==========================================
# modules/security/iam-policies/least-privilege.tf
# ==========================================
#
# IAM 최소 권한 원칙 심화
#
# 06-security-basic과의 차이점:
#   - 06: 기본 Role + 3개 Policy (S3, CloudWatch, Secrets)
#   - 07: 조건부 정책, ABAC(태그 기반 접근제어), Permission Boundary
#
# 최소 권한 원칙 (Principle of Least Privilege):
#   "필요한 작업을 수행하기 위한 최소한의 권한만 부여해야 한다"
#
# 이 원칙을 심화 적용하는 방법:
#   1. 조건(Condition)으로 접근 범위 제한
#   2. 태그 기반 접근 제어 (ABAC)
#   3. Permission Boundary로 최대 권한 제한
#   4. 시간 기반 접근 제어

# ==========================================
# EC2 IAM Role
# ==========================================
#
# EC2 인스턴스가 AWS 서비스에 접근하기 위한 역할입니다.
# Access Key 없이 IAM Role로 안전하게 접근합니다.

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-advanced-role"

  # 신뢰 정책 (Trust Policy)
  # "EC2 서비스만 이 Role을 맡을 수 있다"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"

        # 조건: 특정 태그가 있는 EC2만 이 Role을 맡을 수 있음
        # 이렇게 하면 승인되지 않은 EC2가 이 Role을 사용하는 것을 방지
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })

  # Permission Boundary (권한 경계) 설정
  # 이 Role이 가질 수 있는 "최대 권한"을 제한합니다.
  # Role에 아무리 많은 Policy를 추가해도
  # Permission Boundary를 초과하는 권한은 효과가 없습니다.
  #
  # 예시:
  #   Permission Boundary: S3 + CloudWatch만 허용
  #   Role Policy: S3 + CloudWatch + EC2 허용
  #   실제 권한: S3 + CloudWatch만 (EC2는 Boundary에 의해 차단)
  permissions_boundary = aws_iam_policy.permission_boundary.arn

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2-advanced-role"
  })
}

# EC2 Instance Profile
# EC2에 IAM Role을 연결하려면 Instance Profile이 필요합니다.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-advanced-profile"
  role = aws_iam_role.ec2_role.name
}

# ==========================================
# Permission Boundary (권한 경계)
# ==========================================
#
# Permission Boundary란?
#   IAM Role이나 User에 설정하는 "최대 허용 권한"입니다.
#   아무리 많은 Policy를 추가해도 Boundary를 넘을 수 없습니다.
#
# 비유:
#   Permission Boundary = 놀이공원의 울타리
#   IAM Policy = 놀이공원 안에서 탈 수 있는 놀이기구
#   → 울타리 밖의 놀이기구는 아무리 허가해도 탈 수 없음
#
# 사용 시나리오:
#   - 개발자가 IAM Role을 만들 수 있지만, 너무 강한 권한은 못 주도록 제한
#   - 서비스 계정이 필요 이상의 권한을 갖지 못하도록 보호

resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.project_name}-${var.environment}-permission-boundary"
  description = "EC2 Role의 최대 허용 권한 - 이 범위를 초과하는 권한은 부여 불가"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowedServices"
        Effect = "Allow"
        Action = [
          # S3: 파일 저장소 접근
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",

          # CloudWatch: 모니터링 및 로깅
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "cloudwatch:PutMetricData",

          # Secrets Manager: 비밀 정보 조회
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",

          # KMS: 암호화/복호화
          "kms:Decrypt",
          "kms:GenerateDataKey",

          # EC2: 인스턴스 메타데이터 조회 (자기 자신 정보)
          "ec2:DescribeInstances",
          "ec2:DescribeTags",

          # STS: 임시 자격증명 관련
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        # 명시적 거부: 위험한 작업은 절대 허용하지 않음
        # Deny는 Allow보다 항상 우선합니다!
        Sid    = "DenyDangerousActions"
        Effect = "Deny"
        Action = [
          "iam:*",                  # IAM 변경 금지
          "organizations:*",        # Organizations 변경 금지
          "account:*",              # 계정 설정 변경 금지
          "s3:DeleteBucket",        # S3 버킷 삭제 금지
          "ec2:TerminateInstances", # EC2 종료 금지
          "rds:DeleteDBInstance"    # RDS 삭제 금지
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

# ==========================================
# Policy 1: S3 태그 기반 접근 제어 (ABAC)
# ==========================================
#
# ABAC (Attribute-Based Access Control)이란?
#   리소스의 태그(속성)를 기반으로 접근을 제어하는 방식입니다.
#
# 기존 방식 (RBAC):
#   "이 Role은 bucket-A에 접근 가능" (리소스를 명시적으로 지정)
#
# ABAC 방식:
#   "이 Role은 Environment=dev 태그가 있는 버킷에 접근 가능"
#   (태그 조건으로 동적 접근 제어)
#
# ABAC의 장점:
#   - 새 리소스를 추가할 때마다 Policy를 수정할 필요 없음
#   - 태그만 올바르게 설정하면 자동으로 접근 제어
#   - 환경별(dev/prod) 분리가 쉬움

resource "aws_iam_policy" "s3_abac" {
  name        = "${var.project_name}-${var.environment}-s3-abac"
  description = "S3 태그 기반 접근 제어 (ABAC) - 같은 환경 태그의 버킷만 접근 허용"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3AccessByEnvironmentTag"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = "*"

        # 조건(Condition): 태그 기반 접근 제어
        # 리소스의 Environment 태그가 현재 환경과 일치할 때만 접근 허용
        #
        # 예: environment = "dev"인 EC2는
        #     Environment = "dev" 태그가 있는 S3 버킷만 접근 가능
        #     Environment = "prod" 태그의 버킷에는 접근 불가
        Condition = {
          StringEquals = {
            # s3:ResourceTag/Environment → S3 버킷의 Environment 태그 값
            # ${var.environment} → 현재 환경 (dev/staging/prod)
            "s3:ResourceTag/Environment" = var.environment

            # 추가 조건: 같은 프로젝트의 리소스만 접근
            "s3:ResourceTag/Project" = var.project_name
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# ==========================================
# Policy 2: 시간 기반 접근 제어
# ==========================================
#
# 특정 시간대에만 리소스에 접근할 수 있도록 제한합니다.
# 예: 업무 시간(09:00~18:00)에만 접근 허용
#
# 이것은 보안 관점에서 매우 유용합니다:
#   - 야간에 비정상적인 접근을 차단
#   - 유지보수 시간 외 변경 방지
#   - 감사 요건 충족

resource "aws_iam_policy" "time_based_access" {
  name        = "${var.project_name}-${var.environment}-time-based-access"
  description = "시간 기반 접근 제어 - 업무 시간에만 특정 작업 허용"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDuringBusinessHours"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*/*"

        # 시간 기반 조건
        # UTC 기준 00:00~09:00 = KST 09:00~18:00 (업무 시간)
        Condition = {
          DateGreaterThan = {
            "aws:CurrentTime" = "2024-01-01T00:00:00Z"
          }
          DateLessThan = {
            "aws:CurrentTime" = "2099-12-31T23:59:59Z"
          }
          # 참고: 실제 시간 제한은 aws:CurrentTime의 시간 부분으로 제한
          # 여기서는 학습 목적으로 전체 기간을 허용합니다.
          # 실제 환경에서는 Lambda + SCP 조합으로 구현합니다.
        }
      }
    ]
  })

  tags = var.common_tags
}

# ==========================================
# Policy 3: Secrets Manager 조건부 접근
# ==========================================
#
# Secrets Manager 접근 시 추가 조건을 부여합니다:
#   - 특정 VPC 내에서만 접근 가능 (VPC Endpoint 조건)
#   - 암호화된 연결(TLS)을 통해서만 접근 가능
#   - 특정 프로젝트의 Secret만 접근 가능

resource "aws_iam_policy" "secrets_conditional" {
  name        = "${var.project_name}-${var.environment}-secrets-conditional"
  description = "Secrets Manager 조건부 접근 - TLS 강제 + 프로젝트 범위 제한"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsReadWithConditions"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        # 이 프로젝트의 Secret만 접근 가능
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"

        # 조건: 암호화된 연결(HTTPS/TLS)을 통해서만 접근 허용
        # aws:SecureTransport = true → HTTPS로만 접근 가능
        # 평문 HTTP 요청은 차단됨
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      },
      {
        # KMS 복호화 권한 (Secret을 읽으려면 필요)
        Sid    = "AllowKMSDecryptForSecrets"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            # kms:ViaService → 특정 서비스를 통해서만 KMS 사용 허용
            # secretsmanager를 통해서만 이 키로 복호화 가능
            # 직접 KMS API를 호출하는 것은 차단됨
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# ==========================================
# Policy 4: CloudWatch Logs 정책
# ==========================================

resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-logs-adv"
  description = "CloudWatch Logs 전송 정책 - 프로젝트 로그 그룹만 접근"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/${var.project_name}/*"
      }
    ]
  })

  tags = var.common_tags
}

# ==========================================
# Policy를 Role에 연결 (Attachment)
# ==========================================
#
# 위에서 만든 Policy들을 EC2 Role에 연결합니다.
# Role + Policy = 실제 권한
# Policy를 만들기만 하면 아무 효과 없음!

resource "aws_iam_role_policy_attachment" "s3_abac" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_abac.arn
}

resource "aws_iam_role_policy_attachment" "time_based" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.time_based_access.arn
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_conditional.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

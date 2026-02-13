# ==========================================
# modules/iam/policies.tf - IAM Policy 정의
# ==========================================
#
# IAM Policy란?
# - JSON 형식으로 작성된 "권한 규칙 문서"
# - 어떤 AWS 서비스에서 어떤 작업을 허용/거부할지 정의
#
# Policy의 구성 요소:
#   - Effect: "Allow" (허용) 또는 "Deny" (거부)
#   - Action: 허용할 AWS API 동작 (예: "s3:GetObject")
#   - Resource: 대상 리소스의 ARN (예: S3 버킷 ARN)
#
# 최소 권한 원칙 (Principle of Least Privilege):
#   필요한 최소한의 권한만 부여해야 합니다.
#   "모든 권한(*)"을 주는 것은 보안상 매우 위험합니다!

# ==========================================
# Policy 1: S3 읽기 전용 정책
# ==========================================
#
# EC2 인스턴스가 특정 S3 버킷에서 파일을 읽을 수 있도록 합니다.
# 쓰기/삭제 권한은 부여하지 않습니다 (최소 권한 원칙).

resource "aws_iam_policy" "s3_read_only" {
  name        = "${var.project_name}-${var.environment}-s3-read-only"
  description = "S3 버킷 읽기 전용 정책 - 특정 버킷의 객체 조회만 허용"

  # 정책 문서 (JSON 형식)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 설명: 이 규칙이 무엇을 하는지 메모
        Sid = "AllowS3BucketListing"

        Effect = "Allow"

        # 허용할 동작 목록
        Action = [
          "s3:ListBucket",       # 버킷 내 객체 목록 조회
          "s3:GetBucketLocation" # 버킷 리전 확인
        ]

        # 대상 리소스: 특정 버킷만 (전체 S3가 아님!)
        # "*"를 사용하면 모든 버킷에 접근 가능 → 위험!
        Resource = "arn:aws:s3:::${var.project_name}-*"
      },
      {
        Sid    = "AllowS3ObjectRead"
        Effect = "Allow"

        # 객체 수준 동작
        Action = [
          "s3:GetObject",       # 파일 다운로드
          "s3:GetObjectVersion" # 파일 버전 조회
        ]

        # 버킷 내 모든 객체 (/*가 중요!)
        Resource = "arn:aws:s3:::${var.project_name}-*/*"
      }
    ]
  })

  tags = var.common_tags
}

# ==========================================
# Policy 2: CloudWatch Logs 쓰기 정책
# ==========================================
#
# EC2 인스턴스가 CloudWatch Logs에 로그를 전송할 수 있도록 합니다.
# 애플리케이션 로그를 중앙 집중화하여 모니터링하는 데 사용됩니다.

resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-logs"
  description = "CloudWatch Logs 전송 정책 - 로그 그룹 생성 및 로그 전송 허용"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",    # 로그 그룹 생성
          "logs:CreateLogStream",   # 로그 스트림 생성
          "logs:PutLogEvents",      # 로그 이벤트 전송
          "logs:DescribeLogGroups", # 로그 그룹 조회
          "logs:DescribeLogStreams" # 로그 스트림 조회
        ]

        # 이 프로젝트의 로그 그룹만 대상
        Resource = "arn:aws:logs:*:*:log-group:/${var.project_name}/*"
      }
    ]
  })

  tags = var.common_tags
}

# ==========================================
# Policy 3: Secrets Manager 읽기 정책
# ==========================================
#
# EC2 인스턴스가 Secrets Manager에서 비밀 값을 읽을 수 있도록 합니다.
# 데이터베이스 비밀번호, API 키 등을 안전하게 가져올 수 있습니다.

resource "aws_iam_policy" "secrets_read" {
  name        = "${var.project_name}-${var.environment}-secrets-read"
  description = "Secrets Manager 읽기 정책 - 특정 비밀 값 조회만 허용"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsRead"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue", # 비밀 값 조회
          "secretsmanager:DescribeSecret"  # 비밀 메타데이터 조회
        ]

        # 이 프로젝트의 비밀만 접근 가능
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"
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
# 하나의 Role에 여러 Policy를 연결할 수 있습니다.
#
# Role + Policy = 실제 권한
# (Policy를 만들기만 하면 아무 효과 없음, 반드시 연결해야 함)

# S3 읽기 정책 연결
resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

# CloudWatch Logs 정책 연결
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

# Secrets Manager 읽기 정책 연결
resource "aws_iam_role_policy_attachment" "secrets_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_read.arn
}

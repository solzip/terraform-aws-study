# ==========================================
# modules/monitoring/cloudtrail/audit-trail.tf
# ==========================================
#
# CloudTrail이란?
#   AWS 계정에서 수행되는 모든 API 호출을 기록하는 서비스입니다.
#   "누가, 언제, 어디서, 무엇을 했는지"를 추적합니다.
#
# CloudTrail이 기록하는 정보:
#   - 누가: IAM 사용자/Role (userIdentity)
#   - 언제: 이벤트 발생 시간 (eventTime)
#   - 어디서: 소스 IP, AWS 콘솔/CLI (sourceIPAddress)
#   - 무엇을: API 호출 이름 (eventName)
#   - 결과: 성공/실패 (errorCode)
#
# 이벤트 유형:
#   1. 관리 이벤트 (Management Events)
#      - AWS 리소스 관리 작업 (EC2 생성/삭제, IAM 변경 등)
#      - 무료 (기본 trail 1개)
#
#   2. 데이터 이벤트 (Data Events)
#      - S3 객체 수준 접근, Lambda 호출 등
#      - 유료 (이벤트당 $0.10/100,000)
#
# 활용 예시:
#   - "누가 EC2를 종료했지?"
#   - "IAM 정책을 누가 변경했지?"
#   - "보안 그룹을 누가 열어놨지?"
#   - "이 S3 파일을 누가 삭제했지?"

# ==========================================
# CloudTrail 로그 저장용 S3 버킷
# ==========================================
#
# CloudTrail 로그는 S3 버킷에 JSON 형식으로 저장됩니다.
# 경로 형식: s3://bucket-name/AWSLogs/account-id/CloudTrail/region/year/month/day/

# 고유한 버킷 이름을 위한 랜덤 접미사
resource "random_id" "trail_bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-${var.environment}-trail-${random_id.trail_bucket.hex}"
  force_destroy = true # 학습용: 버킷 삭제 시 객체도 함께 삭제

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudtrail-bucket"
  })
}

# S3 버킷 정책 - CloudTrail이 로그를 쓸 수 있도록 허용
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ==========================================
# CloudTrail 생성
# ==========================================

resource "aws_cloudtrail" "main" {
  name = "${var.project_name}-${var.environment}-trail"

  # 로그 저장 위치
  s3_bucket_name = aws_s3_bucket.cloudtrail.id

  # 멀티 리전 추적
  # true: 모든 AWS 리전의 이벤트를 기록 (보안 권장)
  # false: 현재 리전만 기록
  is_multi_region_trail = false # 학습용으로 현재 리전만

  # 글로벌 서비스 이벤트 포함
  # IAM, STS 등 글로벌 서비스의 이벤트도 기록
  include_global_service_events = true

  # 로그 파일 검증 활성화
  # 로그 파일이 변조되지 않았는지 확인하는 다이제스트 파일 생성
  # 보안 감사에서 로그의 무결성을 증명하는 데 사용
  enable_log_file_validation = true

  # CloudWatch Logs로도 전송 (실시간 모니터링 가능)
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail.arn

  # S3 버킷 정책이 먼저 설정되어야 함
  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudtrail"
  })
}

# ==========================================
# CloudTrail → CloudWatch Logs 연동
# ==========================================
#
# S3에만 저장하면 실시간 분석이 어렵습니다.
# CloudWatch Logs로도 전송하면:
#   - 실시간 로그 검색 가능
#   - Metric Filter로 특정 이벤트 감지
#   - 알람 설정 가능 (예: 루트 로그인 감지)

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/${var.project_name}/${var.environment}/cloudtrail"
  retention_in_days = var.retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudtrail-logs"
  })
}

# CloudTrail이 CloudWatch Logs에 쓸 수 있는 IAM Role
resource "aws_iam_role" "cloudtrail" {
  name = "${var.project_name}-${var.environment}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "cloudtrail_logs" {
  name = "${var.project_name}-${var.environment}-cloudtrail-logs"
  role = aws_iam_role.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# ==========================================
# CloudTrail Metric Filter: 루트 계정 로그인 감지
# ==========================================
#
# 루트 계정으로 로그인하면 즉시 알림을 받습니다.
# 루트 계정은 모든 권한을 가지므로 사용을 최소화해야 합니다.
# 루트 로그인이 감지되면 계정 탈취 가능성을 의심해야 합니다.

resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "${var.project_name}-${var.environment}-root-login"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  # CloudTrail 로그에서 루트 계정 콘솔 로그인을 감지
  pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType = \"AwsConsoleSignIn\" }"

  metric_transformation {
    name          = "RootAccountLogin"
    namespace     = "${var.project_name}/${var.environment}/Security"
    value         = "1"
    default_value = 0
  }
}

# 루트 로그인 알람
resource "aws_cloudwatch_metric_alarm" "root_login" {
  alarm_name        = "${var.project_name}-${var.environment}-root-login-detected"
  alarm_description = "루트 계정 로그인이 감지되었습니다! 즉시 확인하세요."

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountLogin"
  namespace           = "${var.project_name}/${var.environment}/Security"
  period              = 60
  statistic           = "Sum"
  threshold           = 0

  alarm_actions      = var.critical_topic_arn != "" ? [var.critical_topic_arn] : []
  treat_missing_data = "notBreaching"

  tags = merge(var.common_tags, {
    Severity = "Critical"
  })
}

# ==========================================
# modules/monitoring/sns/notifications.tf
# ==========================================
#
# SNS (Simple Notification Service)란?
#   메시지를 발행(Publish)하면 구독자(Subscriber)들에게
#   자동으로 전달하는 완전관리형 메시징 서비스입니다.
#
# SNS의 핵심 개념:
#   ┌──────────┐    ┌───────────┐    ┌──────────────┐
#   │ 발행자   │───▶│ SNS Topic │───▶│ 구독자들     │
#   │(Alarm등) │    │ (주제)    │    │(이메일,Slack)│
#   └──────────┘    └───────────┘    └──────────────┘
#
#   - Topic (토픽): 메시지를 모아두는 채널
#   - Subscription (구독): 토픽에 연결된 수신자
#   - Publish (발행): 토픽에 메시지를 보내는 행위
#
# 구독 프로토콜 종류:
#   - email: 이메일로 알림 (확인 필요)
#   - sms: 문자 메시지 (건당 과금)
#   - https: 웹훅 (Slack, PagerDuty 연동)
#   - lambda: Lambda 함수 트리거
#   - sqs: SQS 큐로 전달

# ==========================================
# SNS Topic: 모니터링 알림
# ==========================================
#
# 모든 모니터링 알림이 이 Topic으로 전달됩니다.
# 여러 구독자가 동시에 알림을 받을 수 있습니다.

resource "aws_sns_topic" "monitoring_alerts" {
  name = "${var.project_name}-${var.environment}-monitoring-alerts"

  # 메시지 전달 정책
  # 전달 실패 시 재시도 횟수와 간격을 설정합니다
  # 기본값을 사용합니다 (HTTP/S 엔드포인트의 경우 3회 재시도)

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-monitoring-alerts"
  })
}

# ==========================================
# SNS Topic: 긴급 알림 (Severity: Critical)
# ==========================================
#
# 토픽을 심각도별로 분리하면:
#   - 긴급 알림: 즉시 대응 필요 (StatusCheck 실패 등)
#   - 일반 알림: 확인 필요하지만 즉시 대응 불필요 (CPU 경고 등)
#
# 심각도별로 다른 구독자를 설정할 수 있습니다:
#   - 긴급: 온콜 담당자 + Slack + PagerDuty
#   - 일반: 팀 이메일 + Slack

resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project_name}-${var.environment}-critical-alerts"

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-${var.environment}-critical-alerts"
    Severity = "Critical"
  })
}

# ==========================================
# SNS Subscription: 이메일 알림
# ==========================================
#
# 이메일 구독은 확인(Confirmation)이 필요합니다!
# terraform apply 후 이메일을 확인하고
# "Confirm subscription" 링크를 클릭해야 합니다.
#
# 확인하지 않으면 알림이 전달되지 않습니다.

resource "aws_sns_topic_subscription" "monitoring_email" {
  # alarm_email이 비어있지 않을 때만 생성
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_sns_topic_subscription" "critical_email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ==========================================
# SNS Topic Policy
# ==========================================
#
# CloudWatch Alarms와 EventBridge가
# SNS Topic에 메시지를 발행할 수 있도록 허용합니다.

resource "aws_sns_topic_policy" "monitoring_alerts" {
  arn = aws_sns_topic.monitoring_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.monitoring_alerts.arn
      },
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.monitoring_alerts.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "critical_alerts" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.critical_alerts.arn
      }
    ]
  })
}

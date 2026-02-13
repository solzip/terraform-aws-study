# ==========================================
# modules/security/vpc-flow-logs/cloudwatch.tf
# ==========================================
#
# VPC Flow Logs를 저장할 CloudWatch Logs 설정
#
# CloudWatch Logs 계층 구조:
#   Log Group (로그 그룹)
#     └ Log Stream (로그 스트림) - ENI별로 자동 생성
#         └ Log Events (로그 이벤트) - 실제 트래픽 레코드
#
# 비용 고려:
#   - 데이터 수집: $0.50/GB (서울 리전)
#   - 데이터 보관: $0.03/GB/월
#   - 학습용이라면 보관 기간을 짧게 설정하여 비용 절감

# ==========================================
# CloudWatch Log Group
# ==========================================
#
# Flow Logs가 저장될 로그 그룹입니다.
# 로그 그룹은 관련 로그 스트림을 묶는 컨테이너 역할입니다.

resource "aws_cloudwatch_log_group" "flow_logs" {
  # 로그 그룹 이름
  # 경로 형태로 구성하면 관리가 편합니다
  name = "/${var.project_name}/${var.environment}/vpc-flow-logs"

  # 로그 보관 기간 (일)
  # 이 기간이 지나면 로그가 자동 삭제됩니다.
  #
  # 허용 값: 0(무기한), 1, 3, 5, 7, 14, 30, 60, 90,
  #          120, 150, 180, 365, 400, 545, 731,
  #          1096, 1827, 2192, 2557, 2922, 3288, 3653
  #
  # 무기한(0)은 비용이 계속 증가하므로 주의!
  retention_in_days = var.retention_days

  # KMS 키로 로그 암호화 (선택사항이지만 보안 권장)
  # 네트워크 트래픽 정보는 민감할 수 있으므로 암호화 권장
  kms_key_id = var.kms_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-flow-logs"
    Type = "VPCFlowLogs"
  })
}

# ==========================================
# CloudWatch Metric Filter - 거부된 트래픽 감지
# ==========================================
#
# Metric Filter란?
#   로그에서 특정 패턴을 찾아 CloudWatch 메트릭으로 변환합니다.
#   이 메트릭에 알람을 설정하면 자동으로 알림을 받을 수 있습니다.
#
# 아래 필터는 "REJECT" (거부된 트래픽)를 감지합니다.
# 많은 REJECT 이벤트는 다음을 의미할 수 있습니다:
#   - 포트 스캔 공격
#   - 잘못된 Security Group 설정
#   - 내부 애플리케이션의 연결 오류

resource "aws_cloudwatch_log_metric_filter" "rejected_traffic" {
  name           = "${var.project_name}-${var.environment}-rejected-traffic"
  log_group_name = aws_cloudwatch_log_group.flow_logs.name

  # 필터 패턴
  # Flow Log에서 "REJECT" 문자열을 포함하는 레코드를 찾습니다
  # [version, account_id, ...] 형태로 필드를 지정할 수도 있습니다
  pattern = "REJECT"

  # 메트릭 변환 설정
  metric_transformation {
    # 메트릭 이름
    name = "RejectedTrafficCount"
    # 메트릭 네임스페이스 (CloudWatch에서 분류용)
    namespace = "${var.project_name}/${var.environment}/VPCFlowLogs"
    # 메트릭 값 (패턴이 매칭될 때마다 1을 더함)
    value = "1"
  }
}

# ==========================================
# CloudWatch Alarm - 비정상 트래픽 알림
# ==========================================
#
# 일정 시간 내에 거부된 트래픽이 임계값을 초과하면
# 알림을 발생시킵니다.
#
# 예: 5분 동안 100건 이상의 REJECT → 포트 스캔 의심

resource "aws_cloudwatch_metric_alarm" "high_rejected_traffic" {
  alarm_name        = "${var.project_name}-${var.environment}-high-rejected-traffic"
  alarm_description = "VPC Flow Logs에서 거부된 트래픽이 임계값 초과 - 보안 위협 가능성"

  # 비교 조건: 메트릭 값이 임계값보다 크거나 같을 때
  comparison_operator = "GreaterThanOrEqualToThreshold"

  # 평가 기간: 1회 (evaluation_periods × period = 총 평가 시간)
  evaluation_periods = 1

  # 메트릭 이름 (위에서 생성한 Metric Filter와 연결)
  metric_name = "RejectedTrafficCount"
  namespace   = "${var.project_name}/${var.environment}/VPCFlowLogs"

  # 평가 주기: 300초 = 5분
  period = 300

  # 통계 방식: 합계 (5분 동안의 총 REJECT 건수)
  statistic = "Sum"

  # 임계값: 100건
  # 5분 동안 100건 이상의 트래픽이 거부되면 알림
  threshold = 100

  # 데이터 부족 시 처리: 알람을 트리거하지 않음
  # "notBreaching" = 데이터가 없으면 정상으로 간주
  treat_missing_data = "notBreaching"

  # SNS 토픽으로 알림 전송 (설정된 경우)
  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rejected-traffic-alarm"
  })
}

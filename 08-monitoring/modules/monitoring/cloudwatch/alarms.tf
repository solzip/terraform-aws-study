# ==========================================
# modules/monitoring/cloudwatch/alarms.tf
# ==========================================
#
# CloudWatch Alarms(알람)란?
#   메트릭 값이 지정한 조건을 충족하면 자동으로 동작을 수행합니다.
#
# 알람의 3가지 상태:
#   - OK: 메트릭이 정상 범위 (녹색)
#   - ALARM: 메트릭이 임계값 초과 (빨간색)
#   - INSUFFICIENT_DATA: 데이터 부족 (회색)
#
# 알람의 동작 (Actions):
#   - SNS 알림 전송 (이메일, Slack)
#   - Auto Scaling 조정 (인스턴스 추가/제거)
#   - EC2 작업 (중지, 종료, 복구)
#   - Lambda 함수 호출
#
# 알람 평가 공식:
#   evaluation_periods × period = 총 평가 시간
#   예: 3 × 300초 = 15분 동안 임계값 초과 시 알람

# ==========================================
# Alarm 1: CPU 사용률 경고
# ==========================================
#
# EC2 인스턴스의 CPU 사용률이 임계값을 초과하면 알림을 보냅니다.
#
# CPU가 높다는 것은:
#   - 트래픽 급증
#   - 애플리케이션 버그 (무한 루프 등)
#   - 리소스 부족 (인스턴스 타입 업그레이드 필요)

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name        = "${var.project_name}-${var.environment}-cpu-high"
  alarm_description = "EC2 CPU 사용률이 ${var.cpu_threshold}%를 초과했습니다. 서버 부하를 확인하세요."

  # 비교 연산자
  # GreaterThanThreshold: 초과 (>)
  # GreaterThanOrEqualToThreshold: 이상 (>=)
  # LessThanThreshold: 미만 (<)
  # LessThanOrEqualToThreshold: 이하 (<=)
  comparison_operator = "GreaterThanThreshold"

  # 평가 기간: 연속 2번의 평가 기간 동안 임계값 초과 시 알람
  # 1번의 스파이크로 알람이 울리는 것을 방지
  evaluation_periods = 2

  # CloudWatch 메트릭 지정
  namespace   = "AWS/EC2"        # EC2 기본 메트릭 네임스페이스
  metric_name = "CPUUtilization" # CPU 사용률 메트릭

  # 평가 주기: 300초 = 5분
  # 5분마다 메트릭 값을 확인
  period = 300

  # 통계 방식: 평균값 사용
  # Average: 평균 / Maximum: 최대값 / Minimum: 최소값 / Sum: 합계
  statistic = "Average"

  # 임계값 (%)
  threshold = var.cpu_threshold

  # 메트릭 필터: 특정 EC2 인스턴스
  dimensions = {
    InstanceId = var.instance_id
  }

  # 알람 발생 시 동작: SNS Topic으로 알림 전송
  alarm_actions = [var.monitoring_topic_arn]

  # 알람 해제 시 동작: OK 상태로 복구되면 알림
  ok_actions = [var.monitoring_topic_arn]

  # 데이터 부족 시 처리
  # "notBreaching": 데이터 없으면 정상으로 간주 (권장)
  # "breaching": 데이터 없으면 알람으로 간주
  # "missing": 상태 유지
  treat_missing_data = "notBreaching"

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-${var.environment}-cpu-high"
    Severity = "Warning"
  })
}

# ==========================================
# Alarm 2: StatusCheck 실패 (긴급)
# ==========================================
#
# EC2 StatusCheck란?
#   AWS가 자동으로 인스턴스 상태를 확인하는 기능입니다.
#
# 두 종류의 StatusCheck:
#   1. System Status Check (시스템 상태)
#      - AWS 인프라 문제 (하드웨어 고장, 네트워크 문제)
#      - 해결 방법: 인스턴스 중지 후 재시작 (다른 물리 서버로 이동)
#
#   2. Instance Status Check (인스턴스 상태)
#      - OS 문제 (커널 패닉, 메모리 부족)
#      - 해결 방법: 인스턴스 재부팅, OS 문제 해결
#
# StatusCheckFailed = 시스템 또는 인스턴스 확인 실패
# 이 알람은 긴급 상황이므로 Critical SNS Topic으로 전송합니다.

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name        = "${var.project_name}-${var.environment}-status-check-failed"
  alarm_description = "EC2 인스턴스 상태 확인 실패! 즉시 확인이 필요합니다."

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1 # 1번만 실패해도 즉시 알람 (긴급)
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60 # 1분 간격으로 확인
  statistic           = "Maximum"
  threshold           = 0 # 0보다 크면 = 실패가 1번이라도 있으면

  dimensions = {
    InstanceId = var.instance_id
  }

  # 긴급 알림 토픽으로 전송
  alarm_actions = [var.critical_topic_arn]
  ok_actions    = [var.critical_topic_arn]

  treat_missing_data = "breaching" # 데이터 없으면 위험으로 간주

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-${var.environment}-status-check"
    Severity = "Critical"
  })
}

# ==========================================
# Alarm 3: 네트워크 트래픽 급증
# ==========================================
#
# 네트워크 아웃바운드 트래픽이 비정상적으로 높으면
# 데이터 유출이나 DDoS 공격의 징후일 수 있습니다.

resource "aws_cloudwatch_metric_alarm" "network_out_high" {
  alarm_name        = "${var.project_name}-${var.environment}-network-out-high"
  alarm_description = "네트워크 아웃바운드 트래픽이 비정상적으로 높습니다."

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"

  # 임계값: 100MB (100 * 1024 * 1024 바이트)
  # 학습용 t2.micro에서는 이 값에 거의 도달하지 않습니다
  threshold = 104857600

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_actions      = [var.monitoring_topic_arn]
  treat_missing_data = "notBreaching"

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-${var.environment}-network-out"
    Severity = "Warning"
  })
}

# ==========================================
# Alarm 4: 애플리케이션 에러 급증
# ==========================================
#
# 커스텀 메트릭(error_count)을 기반으로
# 애플리케이션 에러가 급증하면 알림을 보냅니다.

resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name        = "${var.project_name}-${var.environment}-app-errors"
  alarm_description = "애플리케이션 에러가 5분 동안 10건을 초과했습니다."

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApplicationErrorCount"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = 10 # 5분 동안 10건 초과

  alarm_actions      = [var.monitoring_topic_arn]
  treat_missing_data = "notBreaching"

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-${var.environment}-app-errors"
    Severity = "Warning"
  })
}

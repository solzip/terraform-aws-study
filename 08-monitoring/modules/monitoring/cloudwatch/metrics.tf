# ==========================================
# modules/monitoring/cloudwatch/metrics.tf
# ==========================================
#
# CloudWatch Metrics(메트릭)란?
#   AWS 리소스의 성능 데이터를 시간순으로 기록한 것입니다.
#   "시계열 데이터(Time-Series Data)"라고도 합니다.
#
# 메트릭의 구성 요소:
#   - Namespace: 메트릭의 컨테이너 (예: AWS/EC2)
#   - MetricName: 메트릭 이름 (예: CPUUtilization)
#   - Dimensions: 메트릭을 필터링하는 키-값 쌍 (예: InstanceId=i-xxx)
#   - Value: 실제 값 (예: 75.5)
#   - Timestamp: 값이 기록된 시간
#
# EC2 기본 메트릭 (자동 수집, 5분 간격):
#   ┌────────────────────┬──────────────────────────┐
#   │ 메트릭             │ 설명                     │
#   ├────────────────────┼──────────────────────────┤
#   │ CPUUtilization     │ CPU 사용률 (%)           │
#   │ NetworkIn          │ 수신 네트워크 (바이트)   │
#   │ NetworkOut         │ 송신 네트워크 (바이트)   │
#   │ DiskReadOps        │ 디스크 읽기 횟수         │
#   │ DiskWriteOps       │ 디스크 쓰기 횟수         │
#   │ StatusCheckFailed  │ 상태 확인 실패           │
#   └────────────────────┴──────────────────────────┘
#
# 주의: 메모리(RAM) 사용률은 기본 메트릭에 포함되지 않습니다!
#       CloudWatch Agent를 설치해야 수집 가능합니다.

# ==========================================
# EC2 상세 모니터링 활성화는 monitoring.tf에서 설정
# (aws_instance의 monitoring = true)
# ==========================================
#
# 기본 모니터링: 5분 간격 (무료)
# 상세 모니터링: 1분 간격 (인스턴스당 $3.50/월)
#
# 알람의 정확도를 높이려면 상세 모니터링을 활성화하세요.
# 5분 간격이면 순간적인 스파이크를 놓칠 수 있습니다.

# ==========================================
# 커스텀 메트릭 예시: 로그 기반 에러 카운트
# ==========================================
#
# CloudWatch Logs의 로그 데이터에서 특정 패턴을 찾아
# 커스텀 메트릭으로 변환합니다.
#
# 예: 애플리케이션 로그에서 "ERROR" 문자열이 포함된
#     로그 라인의 수를 메트릭으로 기록

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.project_name}-${var.environment}-error-count"
  log_group_name = var.app_log_group_name

  # 필터 패턴: "ERROR" 문자열을 포함하는 로그 라인
  # 대소문자 구분됨
  #
  # 패턴 문법 예시:
  #   "ERROR"              → ERROR를 포함하는 라인
  #   "ERROR -DEBUG"       → ERROR는 포함, DEBUG는 제외
  #   { $.level = "error" } → JSON 로그의 level 필드가 "error"
  pattern = "ERROR"

  metric_transformation {
    name      = "ApplicationErrorCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1" # 매칭될 때마다 1을 기록

    # 기본값: 패턴이 매칭되지 않는 기간의 메트릭 값
    # 0으로 설정하면 에러가 없는 기간에도 메트릭이 0으로 기록됨
    # (알람 평가에 중요)
    default_value = 0
  }
}

# ==========================================
# 커스텀 메트릭: HTTP 5xx 에러 카운트
# ==========================================
#
# 웹 서버 로그에서 HTTP 500번대 에러를 감지합니다.
# 5xx 에러가 급증하면 서버 장애를 의미할 수 있습니다.

resource "aws_cloudwatch_log_metric_filter" "http_5xx" {
  name           = "${var.project_name}-${var.environment}-http-5xx"
  log_group_name = var.app_log_group_name

  # HTTP 5xx 상태 코드 패턴
  # Apache/Nginx 로그 형식: "GET /path HTTP/1.1" 500
  pattern = "[ip, id, user, timestamp, request, status_code = 5*, size]"

  metric_transformation {
    name          = "HTTP5xxErrorCount"
    namespace     = "${var.project_name}/${var.environment}"
    value         = "1"
    default_value = 0
  }
}

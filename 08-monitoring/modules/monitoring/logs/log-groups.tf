# ==========================================
# modules/monitoring/logs/log-groups.tf
# ==========================================
#
# CloudWatch Logs란?
#   여러 서버에 흩어져 있는 로그 파일을 한 곳으로 모아
#   검색, 보관, 알림에 활용할 수 있게 해주는 서비스입니다.
#
# 왜 로그를 중앙으로 모으는가?
#   - EC2 인스턴스가 종료되면 안에 있던 로그 파일도 함께 사라집니다
#   - 인스턴스가 여러 대면 SSH로 하나씩 접속해서 볼 수 없습니다
#   - 로그를 검색하고 메트릭으로 변환하려면 중앙 저장소가 필요합니다
#
# 로그 계층 구조:
#   ┌────────────────────────────────────────────┐
#   │ Log Group (로그 그룹)                       │
#   │  예: /tf-study/dev/application             │
#   │  - 보관 기간, 암호화 설정의 단위             │
#   │                                            │
#   │  ┌──────────────────────────────────────┐ │
#   │  │ Log Stream (로그 스트림)              │ │
#   │  │  예: i-0abc123 (인스턴스별로 생성)     │ │
#   │  │                                      │ │
#   │  │   Log Event (실제 로그 한 줄)         │ │
#   │  │   2026-08-18T10:00:00 ERROR ...      │ │
#   │  └──────────────────────────────────────┘ │
#   └────────────────────────────────────────────┘
#
#   Log Stream은 보통 Terraform으로 만들지 않습니다.
#   CloudWatch Agent가 인스턴스 ID를 이름으로 자동 생성합니다.
#
# 이 모듈이 만드는 로그 그룹 4종:
#   - application : 애플리케이션이 직접 남기는 로그
#   - system      : OS/데몬 로그 (/var/log/messages 등)
#   - access      : 웹 서버 접근 로그 (누가 어떤 URL을 요청했는지)
#   - error       : 웹 서버 에러 로그
#
#   용도별로 그룹을 나누는 이유:
#   - 보관 기간을 다르게 줄 수 있습니다 (접근 로그는 짧게, 감사 로그는 길게)
#   - 검색 범위가 좁아져서 조회가 빨라지고 비용도 줄어듭니다
#   - 그룹 단위로 권한을 분리할 수 있습니다

# ==========================================
# 로그 그룹 이름 규칙
# ==========================================
#
# CloudTrail 모듈과 동일하게 /프로젝트/환경/용도 형식을 사용합니다.
# 슬래시로 계층을 표현하면 콘솔에서 트리처럼 묶여서 보입니다.

locals {
  log_group_prefix = "/${var.project_name}/${var.environment}"
}

# ==========================================
# Log Group: 애플리케이션 로그
# ==========================================
#
# CloudWatch 모듈의 Metric Filter가 이 그룹을 참조합니다.
# "ERROR" 문자열이나 HTTP 5xx 패턴을 찾아 메트릭으로 변환합니다.

resource "aws_cloudwatch_log_group" "application" {
  name = "${local.log_group_prefix}/application"

  # 보관 기간이 지난 로그 이벤트는 자동 삭제됩니다.
  # 설정하지 않으면 기본값이 "영구 보관"이라 비용이 계속 늘어납니다.
  retention_in_days = var.retention_days

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-application-logs"
    LogType = "application"
  })
}

# ==========================================
# Log Group: 시스템 로그
# ==========================================
#
# OS 레벨 로그입니다. (/var/log/messages, /var/log/secure 등)
# 인스턴스가 재부팅되거나 서비스가 죽은 원인을 추적할 때 사용합니다.

resource "aws_cloudwatch_log_group" "system" {
  name              = "${local.log_group_prefix}/system"
  retention_in_days = var.retention_days

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-system-logs"
    LogType = "system"
  })
}

# ==========================================
# Log Group: 접근 로그
# ==========================================
#
# 웹 서버의 access log입니다. (Apache: /var/log/httpd/access_log)
# 트래픽 분석, 비정상 요청 탐지에 사용합니다.
#
# 접근 로그는 양이 가장 많아 비용에 직접 영향을 줍니다.
# 실무에서는 이 그룹만 보관 기간을 짧게 가져가는 경우가 많습니다.

resource "aws_cloudwatch_log_group" "access" {
  name              = "${local.log_group_prefix}/access"
  retention_in_days = var.retention_days

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-access-logs"
    LogType = "access"
  })
}

# ==========================================
# Log Group: 에러 로그
# ==========================================
#
# 웹 서버의 error log입니다. (Apache: /var/log/httpd/error_log)
# 애플리케이션 로그와 분리해 두면 장애 시 확인 범위가 좁아집니다.

resource "aws_cloudwatch_log_group" "error" {
  name              = "${local.log_group_prefix}/error"
  retention_in_days = var.retention_days

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-error-logs"
    LogType = "error"
  })
}

# ==========================================
# 참고: Metric Filter는 어디에 있는가?
# ==========================================
#
# 로그에서 패턴을 찾아 메트릭으로 바꾸는 Metric Filter는
# 이 모듈이 아니라 cloudwatch 모듈에 있습니다.
# (modules/monitoring/cloudwatch/metrics.tf)
#
# 이유:
#   Metric Filter가 만들어내는 메트릭은 결국 Alarm에서 사용됩니다.
#   메트릭과 알람을 한 모듈에 모아두면 임계값을 바꿀 때
#   한 파일만 보면 되기 때문입니다.
#
# 대신 이 모듈은 로그 그룹 이름을 output으로 넘겨줍니다.
# monitoring.tf에서 module.logs.app_log_group_name을 cloudwatch 모듈에 전달합니다.

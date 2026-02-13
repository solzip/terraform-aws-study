# ==========================================
# modules/security/vpc-flow-logs/main.tf
# ==========================================
#
# VPC Flow Logs란?
#   VPC 내 네트워크 인터페이스(ENI)로 들어오고 나가는
#   IP 트래픽 정보를 캡처하는 기능입니다.
#
# 왜 Flow Logs가 필요한가?
#   1. 보안 모니터링: 비정상적인 트래픽 패턴 감지
#      - 예: 새벽 3시에 대량의 아웃바운드 트래픽 → 데이터 유출 의심
#   2. 네트워크 문제 진단: 연결 실패 원인 파악
#      - 예: Security Group이 트래픽을 거부하는지 확인
#   3. 규정 준수: 네트워크 활동 로그 보관 요건 충족
#
# Flow Log 레코드 예시:
#   2 123456789012 eni-abc123 10.0.1.5 203.0.113.50 443 49152 6 25 20000 ACCEPT
#   │ │            │          │        │            │   │     │ │  │     └ 액션
#   │ │            │          │        │            │   │     │ │  └ 바이트
#   │ │            │          │        │            │   │     │ └ 패킷 수
#   │ │            │          │        │            │   │     └ 프로토콜 (6=TCP)
#   │ │            │          │        │            │   └ 대상 포트
#   │ │            │          │        │            └ 소스 포트
#   │ │            │          │        └ 대상 IP
#   │ │            │          └ 소스 IP
#   │ │            └ ENI ID
#   │ └ AWS 계정 ID
#   └ 버전
#
# Flow Log 저장 위치:
#   1. CloudWatch Logs (이 예시에서 사용)
#      - 실시간 분석에 유리
#      - Metric Filter로 알림 설정 가능
#   2. S3 버킷
#      - 대량 로그 장기 보관에 유리
#      - Athena로 SQL 분석 가능
#   3. Kinesis Data Firehose
#      - 실시간 스트리밍 분석

# ==========================================
# VPC Flow Logs IAM Role
# ==========================================
#
# Flow Logs가 CloudWatch Logs에 로그를 쓰려면
# IAM Role이 필요합니다.
# VPC Flow Logs 서비스가 이 Role을 맡아(Assume)
# CloudWatch에 로그를 전송합니다.

resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-${var.environment}-flow-logs-role"

  # 신뢰 정책: VPC Flow Logs 서비스가 이 Role을 맡을 수 있음
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-flow-logs-role"
  })
}

# Flow Logs Role에 CloudWatch Logs 쓰기 권한 부여
resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-${var.environment}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==========================================
# VPC Flow Logs 리소스
# ==========================================
#
# Flow Log를 VPC 레벨에서 활성화합니다.
# VPC 내 모든 ENI의 트래픽이 기록됩니다.
#
# 캡처 대상 설정 (traffic_type):
#   - "ALL": 모든 트래픽 (허용 + 거부)
#   - "ACCEPT": 허용된 트래픽만
#   - "REJECT": 거부된 트래픽만
#
# 보안 모니터링 목적이라면 "ALL"을 권장합니다.

resource "aws_flow_log" "vpc" {
  # Flow Log를 연결할 VPC ID
  vpc_id = var.vpc_id

  # 트래픽 유형: 모든 트래픽 기록
  traffic_type = "ALL"

  # 로그 저장 위치: CloudWatch Logs
  log_destination_type = "cloud-watch-logs"

  # CloudWatch 로그 그룹 ARN
  log_group_name = aws_cloudwatch_log_group.flow_logs.name

  # Flow Logs 서비스가 사용할 IAM Role
  iam_role_arn = aws_iam_role.flow_logs.arn

  # 로그 수집 간격 (초)
  # 60: 1분 간격 (기본값)
  # 600: 10분 간격 (비용 절감, 세밀한 분석에는 부적합)
  max_aggregation_interval = 60

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  })
}

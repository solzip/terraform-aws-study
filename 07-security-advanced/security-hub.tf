# ==========================================
# security-hub.tf - AWS Security Hub
# ==========================================
#
# Security Hub란?
#   AWS 환경의 보안 상태를 통합적으로 관리하는 서비스입니다.
#
# Security Hub의 역할:
#   1. 통합 대시보드: 여러 보안 서비스의 결과를 하나의 뷰로 제공
#   2. 보안 표준 평가: CIS, PCI DSS 등 표준 기반 자동 평가
#   3. 자동화된 점검: 보안 모범 사례 위반 사항 자동 탐지
#
# Security Hub가 통합하는 서비스들:
#   ┌─────────────────────────────────────────┐
#   │           Security Hub                  │
#   │  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
#   │  │GuardDuty │ │ Config   │ │Inspector│ │
#   │  │(위협탐지) │ │(규칙준수) │ │(취약점) │ │
#   │  └──────────┘ └──────────┘ └─────────┘ │
#   │  ┌──────────┐ ┌──────────┐ ┌─────────┐ │
#   │  │ Macie    │ │Firewall  │ │ IAM     │ │
#   │  │(데이터)  │ │ Manager  │ │Analyzer │ │
#   │  └──────────┘ └──────────┘ └─────────┘ │
#   └─────────────────────────────────────────┘
#
# 보안 표준 (Security Standards):
#   1. AWS Foundational Security Best Practices (FSBP)
#      - AWS가 권장하는 보안 모범 사례
#      - 무료 평가판 기간 동안 사용 가능
#
#   2. CIS AWS Foundations Benchmark
#      - Center for Internet Security에서 정의한 표준
#      - 가장 널리 사용되는 클라우드 보안 표준
#
#   3. PCI DSS v3.2.1
#      - 신용카드 데이터 보안 표준
#      - 결제 관련 서비스에 필수
#
# 비용:
#   - 30일 무료 평가판
#   - 이후: 보안 점검당 $0.0010 (처음 10만 건)
#   - 학습용으로는 무료 평가 기간 내 충분

# ==========================================
# Security Hub 활성화
# ==========================================

resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0

  # Security Hub의 검사 결과를 자동으로 활성화
  # 새로운 보안 컨트롤이 추가될 때 자동으로 활성화됨
  enable_default_standards = true

  # 컨트롤 결과 자동 활성화
  auto_enable_controls = true

  depends_on = [
    # GuardDuty가 먼저 활성화되어야 Security Hub와 통합 가능
    aws_guardduty_detector.main
  ]
}

# ==========================================
# Security Standard: AWS Foundational Security Best Practices
# ==========================================
#
# AWS가 권장하는 보안 모범 사례 표준입니다.
# AWS 서비스별 보안 점검 항목이 포함되어 있습니다.
#
# 점검 항목 예시:
#   - S3 버킷 퍼블릭 접근 차단 여부
#   - EBS 볼륨 암호화 여부
#   - Security Group의 위험한 규칙 여부
#   - IAM 사용자 MFA 활성화 여부
#   - CloudTrail 활성화 여부

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count = var.enable_security_hub ? 1 : 0

  # AWS Foundational Security Best Practices v1.0.0
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.main]
}

# ==========================================
# Security Standard: CIS AWS Foundations Benchmark
# ==========================================
#
# CIS (Center for Internet Security)에서 정의한
# AWS 보안 벤치마크입니다.
#
# 4개 섹션으로 구성:
#   1. IAM (Identity and Access Management)
#   2. Logging (로깅)
#   3. Monitoring (모니터링)
#   4. Networking (네트워킹)

resource "aws_securityhub_standards_subscription" "cis" {
  count = var.enable_security_hub ? 1 : 0

  # CIS AWS Foundations Benchmark v1.2.0
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"

  depends_on = [aws_securityhub_account.main]
}

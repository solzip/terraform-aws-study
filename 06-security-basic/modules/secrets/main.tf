# ==========================================
# modules/secrets/main.tf - Secrets Manager 모듈
# ==========================================
#
# AWS Secrets Manager란?
# - 데이터베이스 비밀번호, API 키, 토큰 등 민감한 정보를
#   안전하게 저장하고 관리하는 서비스
#
# 왜 Secrets Manager를 사용하는가?
#   나쁜 방법:
#     - 코드에 비밀번호를 직접 입력 (하드코딩)
#     - 환경변수에 평문으로 저장
#     - terraform.tfvars에 비밀번호 저장 후 Git 커밋
#
#   좋은 방법:
#     - Secrets Manager에 암호화하여 저장
#     - 애플리케이션이 API로 비밀 값을 조회
#     - IAM 정책으로 접근 제어
#     - 자동 로테이션으로 정기적 변경
#
# 비용:
#   - Secret 1개당 월 $0.40
#   - API 호출 10,000건당 $0.05
#   - 학습용으로 1-2개 Secret은 거의 무료

# ==========================================
# 랜덤 비밀번호 생성
# ==========================================
#
# 데이터베이스 비밀번호를 안전하게 자동 생성합니다.
# 매번 동일한 비밀번호를 사용하는 것보다 랜덤 생성이 더 안전합니다.

resource "random_password" "db_password" {
  length = 20 # 비밀번호 길이 (20자)

  # 포함할 문자 종류
  special          = true                   # 특수문자 포함 (!@#$% 등)
  override_special = "!#$%&*()-_=+[]{}<>:?" # 사용할 특수문자 지정

  # 제외할 문자 (DB 연결 문자열에서 문제 될 수 있는 문자)
  # @, /, \, " 등은 제외
}

# ==========================================
# Secret 1: 데이터베이스 비밀번호
# ==========================================
#
# Secret은 2단계로 생성합니다:
#   1. aws_secretsmanager_secret - Secret의 "컨테이너" 생성 (이름, 암호화 설정)
#   2. aws_secretsmanager_secret_version - 실제 "값"을 저장

# 1단계: Secret 컨테이너 생성
resource "aws_secretsmanager_secret" "db_password" {
  # Secret 이름 (경로 형태로 정리하면 관리가 편합니다)
  name = "${var.project_name}/${var.environment}/db-password"

  # Secret 설명
  description = "${var.environment} 환경 데이터베이스 비밀번호"

  # KMS 키로 암호화
  # Secrets Manager는 기본적으로 AWS 관리형 키로 암호화하지만,
  # 고객 관리형 키(CMK)를 지정하면 더 세밀한 접근 제어가 가능합니다
  kms_key_id = var.kms_key_arn

  # Secret 삭제 시 복구 기간 (일)
  # 0으로 설정하면 즉시 삭제 (학습용)
  # 프로덕션에서는 7~30일 권장
  recovery_window_in_days = 0

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-password"
    Type = "DatabaseCredential"
  })
}

# 2단계: Secret 값 저장
resource "aws_secretsmanager_secret_version" "db_password" {
  # 값을 저장할 Secret (위에서 생성한 컨테이너)
  secret_id = aws_secretsmanager_secret.db_password.id

  # 저장할 값 (JSON 형식으로 여러 필드를 저장할 수 있음)
  # 데이터베이스 접속에 필요한 정보를 모아서 저장
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    engine   = "mysql"
    host     = "db.example.com"
    port     = 3306
    dbname   = "${var.project_name}_${var.environment}"
  })
}

# ==========================================
# Secret 2: API 키 (예시)
# ==========================================
#
# 외부 서비스 API 키를 저장하는 예시입니다.
# 실제 API 키 대신 더미 값을 사용합니다.

resource "aws_secretsmanager_secret" "api_key" {
  name        = "${var.project_name}/${var.environment}/api-key"
  description = "${var.environment} 환경 외부 서비스 API 키"
  kms_key_id  = var.kms_key_arn

  recovery_window_in_days = 0

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-api-key"
    Type = "APICredential"
  })
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id

  secret_string = jsonencode({
    api_key    = "dummy-api-key-for-learning"
    api_secret = "dummy-api-secret-for-learning"
    endpoint   = "https://api.example.com/v1"
  })
}

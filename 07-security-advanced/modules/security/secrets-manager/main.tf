# ==========================================
# modules/security/secrets-manager/main.tf
# ==========================================
#
# AWS Secrets Manager 심화 모듈
#
# 06-security-basic과의 차이점:
#   - 06에서는 단순히 Secret을 생성하고 값을 저장
#   - 07에서는 자동 로테이션, 리소스 정책, 복구 설정 등 추가
#
# Secrets Manager의 고급 기능:
#   1. 자동 로테이션 - Lambda로 주기적 비밀번호 교체
#   2. 리소스 정책 - Secret 레벨의 접근 제어
#   3. 복제(Replication) - 다른 리전으로 Secret 복제
#   4. 버전 관리 - 이전 값 추적 (AWSPREVIOUS, AWSCURRENT)

# ==========================================
# 랜덤 비밀번호 생성
# ==========================================
#
# 매번 사람이 비밀번호를 만드는 것보다
# 암호학적으로 안전한 랜덤 비밀번호를 자동 생성하는 것이 좋습니다.
#
# 좋은 비밀번호의 조건:
#   - 충분한 길이 (20자 이상)
#   - 대소문자, 숫자, 특수문자 포함
#   - DB 연결 문자열에서 문제 되는 문자 제외

resource "random_password" "db_password" {
  length = 24 # 24자 (06-basic의 20자보다 더 길게)

  # 문자 종류 설정
  special          = true                   # 특수문자 포함
  override_special = "!#$%&*()-_=+[]{}<>:?" # 사용할 특수문자 지정

  # DB 연결 문자열에서 문제가 되는 문자는 제외됨:
  #   @ → DB 사용자명과 혼동
  #   / → 경로 구분자와 혼동
  #   \ → 이스케이프 문자와 혼동
  #   " → 문자열 구분자와 혼동
  #   ' → SQL 인젝션 위험

  # lifecycle 블록:
  #   이 비밀번호가 한번 생성되면, Terraform이
  #   다시 실행될 때 변경되지 않도록 보호합니다.
  #   (비밀번호가 매번 바뀌면 DB 접속이 끊김!)
  lifecycle {
    ignore_changes = [
      length,
      special,
      override_special,
    ]
  }
}

# ==========================================
# Secret 컨테이너 생성
# ==========================================
#
# Secret은 2단계로 생성됩니다:
#   1단계: Secret "컨테이너" 생성 (이름, 암호화 설정)
#          → aws_secretsmanager_secret
#   2단계: 실제 "값" 저장
#          → aws_secretsmanager_secret_version
#
# Secret 이름을 경로 형태로 만들면 관리가 편합니다:
#   project-name/environment/secret-type
#   예: tf-security-adv/dev/db-password

resource "aws_secretsmanager_secret" "db_credentials" {
  # Secret 이름 (경로 형태)
  # 예: tf-security-adv/dev/db-credentials
  name = "${var.project_name}/${var.environment}/db-credentials"

  description = "${var.environment} 환경 데이터베이스 자격증명 (자동 로테이션 지원)"

  # KMS 키로 암호화
  # AWS 관리형 키(기본) 대신 고객 관리형 키(CMK) 사용
  # CMK를 사용하면:
  #   - KMS 키 정책으로 누가 복호화할 수 있는지 제어
  #   - CloudTrail에서 키 사용 이력 추적
  #   - 키 로테이션 정책 직접 관리
  kms_key_id = var.kms_key_arn

  # 삭제 복구 기간 (일)
  # Secret을 삭제한 후 이 기간 내에 복구할 수 있습니다.
  #   - 0: 즉시 삭제 (학습용)
  #   - 7~30: 프로덕션 권장 (실수 방지)
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-credentials"
    Type = "DatabaseCredential"

    # 자동 로테이션 활성화 상태 태그
    # 이 태그로 어떤 Secret이 로테이션 설정되었는지 쉽게 확인
    AutoRotation = var.enable_rotation ? "enabled" : "disabled"
  })
}

# ==========================================
# Secret 값 저장
# ==========================================
#
# JSON 형식으로 여러 필드를 한 Secret에 저장합니다.
# 이렇게 하면 관련 자격증명을 한곳에서 관리할 수 있습니다.

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  # JSON 형식으로 DB 접속 정보 저장
  # 실제 환경에서는 host, port, dbname 등이
  # 실제 RDS 엔드포인트로 설정됩니다.
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    engine   = "mysql"
    host     = "db.${var.environment}.internal"
    port     = 3306
    dbname   = "${var.project_name}_${var.environment}"
  })

  # lifecycle: Secret 값이 외부에서 변경되어도 Terraform이 되돌리지 않음
  # 자동 로테이션 Lambda가 비밀번호를 변경하면,
  # 다음 terraform apply 시 원래 값으로 되돌아가는 것을 방지
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ==========================================
# API 키 Secret (추가 예시)
# ==========================================
#
# 외부 서비스의 API 키를 저장하는 예시입니다.
# 실제 환경에서는 이런 외부 API 자격증명도
# Secrets Manager로 안전하게 관리합니다.

resource "aws_secretsmanager_secret" "api_credentials" {
  name        = "${var.project_name}/${var.environment}/api-credentials"
  description = "${var.environment} 환경 외부 API 자격증명"
  kms_key_id  = var.kms_key_arn

  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-api-credentials"
    Type = "APICredential"
  })
}

resource "aws_secretsmanager_secret_version" "api_credentials" {
  secret_id = aws_secretsmanager_secret.api_credentials.id

  secret_string = jsonencode({
    api_key    = "dummy-api-key-for-learning-${var.environment}"
    api_secret = "dummy-api-secret-for-learning-${var.environment}"
    endpoint   = "https://api.example.com/v1"
  })
}

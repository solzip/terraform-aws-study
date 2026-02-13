# ==========================================
# modules/security/secrets-manager/rotation.tf
# ==========================================
#
# Secret 자동 로테이션 설정
#
# 자동 로테이션이란?
#   정해진 주기(예: 30일)마다 Lambda 함수가 자동으로:
#   1. 새로운 비밀번호를 생성
#   2. 데이터베이스의 비밀번호를 변경
#   3. Secrets Manager의 값을 업데이트
#
# 왜 자동 로테이션이 필요한가?
#   - 비밀번호를 오랫동안 변경하지 않으면 유출 위험 증가
#   - 수동 변경은 실수나 누락이 발생할 수 있음
#   - 규정 준수 요건(PCI DSS, SOC 2 등)에서 주기적 변경 요구
#
# 로테이션 과정 (4단계):
#   Step 1: createSecret
#     - 새 비밀번호 생성 → AWSPENDING 버전으로 저장
#
#   Step 2: setSecret
#     - DB에 새 비밀번호 적용 (ALTER USER)
#
#   Step 3: testSecret
#     - 새 비밀번호로 DB 접속 테스트
#
#   Step 4: finishSecret
#     - AWSPENDING → AWSCURRENT로 승격
#     - 기존 값은 AWSPREVIOUS로 이동

# ==========================================
# 로테이션 Lambda 함수
# ==========================================
#
# 이 Lambda가 Secrets Manager에 의해 주기적으로 호출되어
# 비밀번호를 자동 교체합니다.
#
# 실제 프로덕션에서는:
#   - AWS에서 제공하는 로테이션 템플릿을 사용하거나
#   - 회사의 DB 환경에 맞게 커스텀 Lambda를 작성합니다
#
# 학습 목적으로 간단한 더미 Lambda를 생성합니다.

# Lambda 코드를 ZIP으로 패키징
# archive_file 데이터 소스는 코드를 자동으로 ZIP 파일로 만듭니다
data "archive_file" "rotation_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda/rotation.zip"

  # 인라인 소스로 Lambda 코드 작성
  # 실제 환경에서는 별도의 .py 파일로 관리하지만,
  # 학습 목적으로 Terraform 내에서 직접 정의합니다
  source {
    content  = <<-PYTHON
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Secrets Manager 자동 로테이션 Lambda 핸들러

    이 함수는 Secrets Manager가 자동으로 호출합니다.
    event에는 다음 정보가 포함됩니다:
      - SecretId: 로테이션할 Secret의 ARN
      - ClientRequestToken: 새 버전의 고유 ID
      - Step: 현재 로테이션 단계 (createSecret/setSecret/testSecret/finishSecret)

    학습용 더미 구현:
      실제로는 각 Step에 맞는 로직을 구현해야 합니다.
      여기서는 로깅만 수행합니다.
    """
    secret_arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']

    logger.info(f"Rotation step: {step}")
    logger.info(f"Secret ARN: {secret_arn}")
    logger.info(f"Token: {token}")

    # Secrets Manager 클라이언트 생성
    sm_client = boto3.client('secretsmanager')

    if step == "createSecret":
        # Step 1: 새 비밀번호를 생성하고 AWSPENDING 버전에 저장
        logger.info("Step 1: Creating new secret version (AWSPENDING)")
        # 실제 구현: sm_client.get_random_password() 로 새 비밀번호 생성
        # sm_client.put_secret_value(SecretId=secret_arn, ClientRequestToken=token, ...)

    elif step == "setSecret":
        # Step 2: 실제 리소스(DB 등)에 새 비밀번호 적용
        logger.info("Step 2: Setting new secret in the resource")
        # 실제 구현: DB에 접속하여 ALTER USER 실행

    elif step == "testSecret":
        # Step 3: 새 비밀번호로 리소스 접속 테스트
        logger.info("Step 3: Testing new secret")
        # 실제 구현: 새 비밀번호로 DB 접속 시도

    elif step == "finishSecret":
        # Step 4: AWSPENDING → AWSCURRENT 승격
        logger.info("Step 4: Finishing rotation")
        # 실제 구현: sm_client.update_secret_version_stage() 호출

    else:
        raise ValueError(f"Unknown rotation step: {step}")

    return {
        'statusCode': 200,
        'body': json.dumps(f'Rotation step {step} completed')
    }
    PYTHON
    filename = "lambda_function.py"
  }
}

# ==========================================
# Lambda 실행 역할 (IAM Role)
# ==========================================
#
# Lambda 함수가 AWS 서비스에 접근하려면 IAM Role이 필요합니다.
# 이 Role은 Lambda가 맡을(Assume) 수 있는 신뢰 정책과
# 실제 수행할 수 있는 권한 정책으로 구성됩니다.

# Lambda 실행용 IAM Role
resource "aws_iam_role" "rotation_lambda" {
  name = "${var.project_name}-${var.environment}-rotation-lambda-role"

  # 신뢰 정책 (Trust Policy)
  # "Lambda 서비스가 이 Role을 맡을 수 있다"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rotation-lambda-role"
  })
}

# Lambda 실행에 필요한 권한 정책
resource "aws_iam_role_policy" "rotation_lambda" {
  name = "${var.project_name}-${var.environment}-rotation-lambda-policy"
  role = aws_iam_role.rotation_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Secrets Manager 접근 권한
        # 로테이션 Lambda가 Secret 값을 읽고 쓸 수 있어야 함
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",           # Secret 값 조회
          "secretsmanager:PutSecretValue",           # 새 값 저장
          "secretsmanager:UpdateSecretVersionStage", # 버전 승격
          "secretsmanager:DescribeSecret"            # Secret 메타데이터 조회
        ]
        # 이 프로젝트의 Secret만 접근 가능 (최소 권한 원칙)
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}/*"
      },
      {
        # KMS 복호화 권한
        # Secret을 읽으려면 KMS 키로 복호화해야 함
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      },
      {
        # CloudWatch Logs 권한
        # Lambda 실행 로그를 CloudWatch에 기록
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ==========================================
# Lambda 함수 생성
# ==========================================

resource "aws_lambda_function" "secret_rotation" {
  filename         = data.archive_file.rotation_lambda.output_path
  source_code_hash = data.archive_file.rotation_lambda.output_base64sha256

  function_name = "${var.project_name}-${var.environment}-secret-rotation"
  role          = aws_iam_role.rotation_lambda.arn

  # Python 3.12 런타임
  # Lambda가 지원하는 최신 Python 버전
  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  # Lambda 실행 제한
  timeout     = 60  # 최대 60초 (로테이션은 보통 빨리 완료됨)
  memory_size = 128 # 128MB (최소값, 로테이션에 충분)

  # 환경 변수
  # Lambda 코드에서 os.environ으로 접근 가능
  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-secret-rotation"
  })
}

# ==========================================
# Secrets Manager가 Lambda를 호출할 수 있도록 권한 부여
# ==========================================
#
# Lambda 함수는 기본적으로 외부에서 호출할 수 없습니다.
# Secrets Manager가 이 Lambda를 호출할 수 있도록
# Resource-based Policy를 추가합니다.

resource "aws_lambda_permission" "secrets_manager" {
  statement_id  = "AllowSecretsManagerInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation.function_name

  # Secrets Manager 서비스가 호출 가능
  principal = "secretsmanager.amazonaws.com"
}

# ==========================================
# 자동 로테이션 스케줄 설정
# ==========================================
#
# Secret에 로테이션 스케줄을 설정합니다.
# enable_rotation이 true일 때만 활성화됩니다.
#
# 로테이션이 설정되면:
#   1. 지정된 주기(rotation_days)마다 Lambda가 자동 호출
#   2. Lambda가 4단계 로테이션 수행
#   3. 새 비밀번호가 AWSCURRENT 버전이 됨

resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  # enable_rotation이 true일 때만 생성
  count = var.enable_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn

  # 로테이션 규칙
  rotation_rules {
    # 자동 로테이션 주기 (일)
    # 예: 30일마다 비밀번호 자동 교체
    automatically_after_days = var.rotation_days
  }

  # Lambda 권한이 먼저 설정되어야 함
  depends_on = [aws_lambda_permission.secrets_manager]
}

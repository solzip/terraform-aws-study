# LocalStack용 AWS Provider 설정
# 로컬 환경에서 AWS 서비스를 시뮬레이션하기 위한 설정

# AWS Provider - LocalStack 엔드포인트로 연결
provider "aws" {
  # LocalStack은 기본적으로 ap-northeast-2 리전 사용
  region = var.aws_region

  # LocalStack 테스트용 자격증명 (실제 AWS 키가 아님)
  access_key = "test"
  secret_key = "test"

  # AWS API 검증 우회 (LocalStack이므로 실제 AWS 검증 불필요)
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # LocalStack 엔드포인트 설정
  # 모든 AWS 서비스가 localhost:4566으로 통합됨
  endpoints {
    # Compute
    ec2            = "http://localhost:4566"

    # Storage
    s3             = "http://s3.localhost.localstack.cloud:4566"  # S3는 특별한 엔드포인트 사용
    ebs            = "http://localhost:4566"

    # Database
    dynamodb       = "http://localhost:4566"
    rds            = "http://localhost:4566"

    # Networking
    elb            = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
    route53        = "http://localhost:4566"

    # Security & Identity
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
    kms            = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"

    # Management & Governance
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    logs           = "http://localhost:4566"

    # Application Integration
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"

    # Lambda
    lambda         = "http://localhost:4566"

    # Analytics
    kinesis        = "http://localhost:4566"
    firehose       = "http://localhost:4566"

    # API Gateway
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
  }

  # LocalStack에서는 기본 태그가 제대로 작동하지 않을 수 있음
  # 하지만 연습을 위해 포함
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Backend     = "LocalStack"
    }
  }
}

# ==========================================
# LocalStack 특징 및 제약사항
# ==========================================
#
# 장점:
# - 비용 없이 무제한 테스트 가능
# - 빠른 리소스 생성/삭제
# - 오프라인 개발 가능
# - CI/CD 파이프라인에서 활용 가능
#
# 제약사항:
# - 일부 AWS 서비스 미지원
# - Pro 버전에서만 사용 가능한 기능 있음
# - 실제 AWS와 100% 동일하지 않음
# - EC2 인스턴스는 실제로 실행되지 않음 (메타데이터만 저장)
#
# 무료 버전에서 지원되는 주요 서비스:
# - EC2 (메타데이터만)
# - S3
# - DynamoDB
# - Lambda
# - SQS
# - SNS
# - CloudFormation
# - CloudWatch Logs
# - IAM
# - STS
#
# Pro 버전이 필요한 서비스:
# - ECS
# - EKS
# - RDS (일부 기능)
# - ElastiCache
# - etc.
#
# ==========================================
# LocalStack 엔드포인트 확인
# ==========================================
#
# LocalStack이 실행 중인지 확인:
# $ curl http://localhost:4566/_localstack/health
#
# 응답 예시:
# {
#   "services": {
#     "ec2": "running",
#     "s3": "running",
#     "dynamodb": "running"
#   }
# }
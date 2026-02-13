# ==========================================
# backend-setup/main.tf
# ==========================================
#
# 이 파일은 Terraform State를 원격으로 저장하기 위한
# "Backend 인프라"를 생성합니다.
#
# 생성하는 리소스:
#   1. S3 버킷 - State 파일을 저장하는 저장소
#   2. DynamoDB 테이블 - State 잠금(Locking)을 위한 테이블
#
# 실행 순서:
#   이 코드를 먼저 실행하여 S3 + DynamoDB를 생성한 뒤,
#   상위 디렉토리의 main.tf에서 이 버킷을 Backend로 사용합니다.
#
# 주의사항:
#   - 이 코드 자체의 State는 로컬에 저장됩니다 (닭과 달걀 문제)
#   - Backend 인프라는 다른 Terraform 코드보다 먼저 생성해야 합니다
#   - 삭제 시에는 다른 인프라를 먼저 삭제한 뒤 이 Backend를 삭제하세요

# ==========================================
# Terraform 및 Provider 설정
# ==========================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 이 코드의 State는 로컬에 저장합니다
  # (Backend 인프라를 만들기 전이므로 원격 저장 불가)
  # 이를 "닭과 달걀 문제(Chicken-and-Egg Problem)"라고 합니다
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "terraform-state-backend"
      ManagedBy = "Terraform"
      Purpose   = "Terraform State Management"
    }
  }
}

# ==========================================
# 변수 정의
# ==========================================

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 (버킷 이름에 사용)"
  type        = string
  default     = "terraform-study"
}

# ==========================================
# 랜덤 문자열 생성 (버킷 이름 고유성 보장)
# ==========================================
#
# S3 버킷 이름은 전 세계적으로 고유해야 합니다.
# 랜덤 문자열을 추가하여 이름 충돌을 방지합니다.
# 예: "terraform-study-state-a1b2c3d4"

resource "random_id" "bucket_suffix" {
  byte_length = 4 # 8자리 16진수 문자열 생성 (예: a1b2c3d4)
}

# ==========================================
# S3 Bucket - State 파일 저장소
# ==========================================
#
# Terraform State 파일(.tfstate)을 저장하는 S3 버킷입니다.
#
# State 파일이란?
# - Terraform이 관리하는 인프라의 "현재 상태"를 기록한 JSON 파일
# - 어떤 리소스가 생성되었고, 각 리소스의 속성은 무엇인지 저장
# - 이 파일이 없으면 Terraform은 기존 인프라를 인식하지 못함
#
# 왜 S3에 저장하는가?
# - 팀원 모두가 동일한 State에 접근 가능 (협업)
# - 버전 관리로 실수로 인한 State 손실 방지 (복구)
# - 암호화로 민감 정보 보호 (보안)

resource "aws_s3_bucket" "terraform_state" {
  # 버킷 이름: "프로젝트명-state-랜덤문자열"
  # 예: "terraform-study-state-a1b2c3d4"
  bucket = "${var.project_name}-state-${random_id.bucket_suffix.hex}"

  # 실수로 버킷을 삭제하지 못하도록 보호
  # true로 설정하면 terraform destroy 시에도 삭제되지 않음
  # 학습 환경에서는 false로 설정 (정리 편의)
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-terraform-state"
    Description = "Terraform State 파일 저장용 S3 버킷"
  }
}

# ==========================================
# S3 버킷 버전 관리 활성화
# ==========================================
#
# 버전 관리를 활성화하면:
# - State 파일이 변경될 때마다 이전 버전이 보존됨
# - 실수로 State를 덮어써도 이전 버전으로 복구 가능
# - terraform apply 할 때마다 새 버전이 생성됨
#
# 예시: State 히스토리
#   v3 (최신) - EC2 인스턴스 추가 후
#   v2         - VPC 생성 후
#   v1         - 초기 상태

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    # "Enabled" : 버전 관리 활성화
    # "Suspended" : 일시 중지 (기존 버전은 유지)
    # "Disabled" : 비활성화
    status = "Enabled"
  }
}

# ==========================================
# S3 버킷 암호화 설정
# ==========================================
#
# State 파일에는 민감한 정보가 포함될 수 있습니다:
# - 데이터베이스 비밀번호
# - API 키
# - 리소스 ARN 등
#
# 서버 측 암호화(SSE)를 활성화하여
# S3에 저장될 때 자동으로 암호화되도록 합니다.
#
# AES-256 vs KMS:
# - AES-256 (aws:s3) : AWS가 관리하는 키로 암호화 (무료)
# - KMS : 사용자가 관리하는 키로 암호화 (유료, 더 세밀한 제어)

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      # AES-256 암호화 사용 (무료, 학습용으로 충분)
      # 프로덕션에서는 KMS(aws:kms)를 권장합니다
      sse_algorithm = "AES256"
    }

    # 버킷의 모든 객체에 암호화 강제
    bucket_key_enabled = true
  }
}

# ==========================================
# S3 버킷 퍼블릭 접근 차단
# ==========================================
#
# State 파일은 절대로 퍼블릭으로 노출되면 안 됩니다!
# 모든 퍼블릭 접근을 완전히 차단합니다.
#
# 4가지 차단 옵션:
# - block_public_acls       : 퍼블릭 ACL 설정 차단
# - block_public_policy     : 퍼블릭 버킷 정책 차단
# - ignore_public_acls      : 기존 퍼블릭 ACL 무시
# - restrict_public_buckets : 퍼블릭 버킷 접근 제한

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true # 퍼블릭 ACL 차단
  block_public_policy     = true # 퍼블릭 정책 차단
  ignore_public_acls      = true # 기존 퍼블릭 ACL 무시
  restrict_public_buckets = true # 퍼블릭 접근 완전 제한
}

# ==========================================
# DynamoDB Table - State 잠금(Locking)
# ==========================================
#
# State Locking이란?
# - 여러 사람이 동시에 terraform apply를 실행하면 State가 충돌할 수 있음
# - DynamoDB 테이블을 사용하여 "잠금"을 구현
# - 한 명이 apply 중이면 다른 사람은 대기해야 함
#
# 동작 방식:
#   1. terraform apply 시작 → DynamoDB에 잠금 레코드 생성
#   2. 다른 사람이 apply 시도 → 잠금이 있으므로 에러 발생
#   3. 첫 번째 apply 완료 → 잠금 레코드 삭제
#   4. 다른 사람이 다시 시도 → 성공
#
# 필수 설정:
# - 파티션 키(Hash Key) 이름은 반드시 "LockID"여야 합니다
# - Terraform이 이 키 이름을 하드코딩하여 사용합니다

resource "aws_dynamodb_table" "terraform_lock" {
  # 테이블 이름
  name = "${var.project_name}-terraform-lock"

  # 과금 방식: PAY_PER_REQUEST (온디맨드)
  # - 사용한 만큼만 과금 (Terraform 잠금은 사용량이 매우 적음)
  # - PROVISIONED 방식보다 간편하고 저렴 (소량 사용 시)
  billing_mode = "PAY_PER_REQUEST"

  # 파티션 키 설정
  # ⚠️ 반드시 "LockID"라는 이름의 문자열(S) 타입이어야 합니다!
  # Terraform이 이 이름으로 잠금을 관리합니다
  hash_key = "LockID"

  attribute {
    name = "LockID" # 잠금 식별자 (키 이름 변경 불가!)
    type = "S"      # S = String (문자열)
  }

  tags = {
    Name        = "${var.project_name}-terraform-lock"
    Description = "Terraform State 잠금용 DynamoDB 테이블"
  }
}

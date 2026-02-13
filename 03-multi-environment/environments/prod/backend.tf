# environments/prod/backend.tf
# Production 환경의 Terraform State Backend 설정
#
# Prod State는 특히 엄격한 접근 제어 필요:
# - S3 버킷 정책으로 접근 제한
# - DynamoDB를 이용한 State 잠금 필수
# - 버전 관리 활성화로 State 복구 가능

# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-state-prod"
#     key            = "03-multi-environment/prod/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#     dynamodb_table = "terraform-lock-prod"
#   }
# }
#
# 참고: 학습 환경에서는 로컬 backend를 사용합니다.
# S3 backend를 사용하려면 위 주석을 해제하세요.
#
# Prod backend 보안 체크리스트:
# - [ ] S3 버킷 버전 관리 활성화
# - [ ] S3 버킷 암호화 (AES-256 또는 KMS)
# - [ ] DynamoDB 테이블 생성 (State 잠금용)
# - [ ] IAM 정책으로 접근 제한
# - [ ] S3 버킷 로깅 활성화

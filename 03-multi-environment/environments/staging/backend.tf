# environments/staging/backend.tf
# Staging 환경의 Terraform State Backend 설정

# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-state-staging"
#     key            = "03-multi-environment/staging/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#     dynamodb_table = "terraform-lock-staging"
#   }
# }
#
# 참고: 학습 환경에서는 로컬 backend를 사용합니다.
# S3 backend를 사용하려면 위 주석을 해제하세요.

# environments/dev/backend.tf
# Dev 환경의 Terraform State Backend 설정
#
# S3 Backend를 사용하여 State 파일을 원격으로 관리
# 각 환경별로 별도의 버킷/키를 사용하여 State 격리
#
# 사용 방법:
#   cd environments/dev
#   terraform init -backend-config=backend.tf ../../
#
# 또는 루트에서:
#   terraform init
#   terraform apply -var-file=environments/dev/terraform.tfvars

# terraform {
#   backend "s3" {
#     bucket         = "my-terraform-state-dev"
#     key            = "03-multi-environment/dev/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#     dynamodb_table = "terraform-lock-dev"
#   }
# }
#
# 참고: 학습 환경에서는 로컬 backend를 사용합니다.
# S3 backend를 사용하려면 위 주석을 해제하고
# 먼저 S3 버킷과 DynamoDB 테이블을 생성해야 합니다.
# (05-remote-state 브랜치에서 자세히 다룹니다)

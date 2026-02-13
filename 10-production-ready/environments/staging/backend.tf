# ==========================================
# staging 환경 Backend 설정
# ==========================================
#
# staging 환경은 prod와 동일한 구조로 State를 관리합니다.
# key만 "staging/terraform.tfstate"로 변경하여
# dev/prod State와 분리합니다.

terraform {
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "staging/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

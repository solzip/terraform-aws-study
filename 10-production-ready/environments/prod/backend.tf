# ==========================================
# prod (프로덕션) 환경 Backend 설정
# ==========================================
#
# 프로덕션 State 관리 주의사항:
#   1. State 파일은 인프라의 "진실의 원천"입니다
#   2. 손상되면 인프라 관리가 불가능해집니다
#   3. S3 Versioning으로 이전 버전 복구 가능
#   4. DynamoDB Lock으로 동시 수정 방지 필수
#
# 프로덕션에서는 반드시 원격 Backend를 사용하세요!

terraform {
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "prod/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

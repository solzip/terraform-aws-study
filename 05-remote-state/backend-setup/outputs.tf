# ==========================================
# backend-setup/outputs.tf
# ==========================================
#
# Backend 인프라 생성 후 출력되는 값입니다.
# 이 값들을 상위 디렉토리의 backend.hcl 또는 backend.tf에서 사용합니다.
#
# 사용 방법:
#   terraform output s3_bucket_name
#   → 출력된 버킷 이름을 backend.hcl의 bucket 값에 복사

# ==========================================
# S3 버킷 정보
# ==========================================

output "s3_bucket_name" {
  description = "State를 저장할 S3 버킷 이름 (backend.hcl의 bucket에 사용)"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "S3 버킷의 ARN (IAM 정책 작성 시 필요)"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_region" {
  description = "S3 버킷의 리전"
  value       = var.aws_region
}

# ==========================================
# DynamoDB 테이블 정보
# ==========================================

output "dynamodb_table_name" {
  description = "State 잠금에 사용할 DynamoDB 테이블 이름 (backend.hcl의 dynamodb_table에 사용)"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB 테이블의 ARN"
  value       = aws_dynamodb_table.terraform_lock.arn
}

# ==========================================
# Backend 설정 요약 (사용자 편의)
# ==========================================

output "backend_config_summary" {
  description = "backend.hcl에 넣을 설정 요약"
  value       = <<-EOT

  ============================================
   Backend 설정 정보
  ============================================

   아래 값을 backend.hcl 파일에 복사하세요:

   bucket         = "${aws_s3_bucket.terraform_state.id}"
   key            = "05-remote-state/terraform.tfstate"
   region         = "${var.aws_region}"
   encrypt        = true
   dynamodb_table = "${aws_dynamodb_table.terraform_lock.name}"

  ============================================

  EOT
}

# ==========================================
# backend.tf - S3 원격 Backend 설정
# ==========================================
#
# 이 파일은 Terraform State를 S3 버킷에 저장하도록 설정합니다.
#
# Backend란?
# - Terraform이 State 파일을 어디에 저장할지 결정하는 설정
# - 기본값은 "local" (로컬 파일시스템에 terraform.tfstate로 저장)
# - "s3" backend를 사용하면 AWS S3에 원격으로 저장
#
# 사전 준비:
# - backend-setup/ 디렉토리에서 S3 버킷과 DynamoDB 테이블을 먼저 생성해야 합니다
#
# 초기화 방법:
#   terraform init -backend-config=backend.hcl
#
# 주의사항:
# - backend 블록 안에서는 변수(var.xxx)를 사용할 수 없습니다!
# - 그래서 -backend-config 옵션이나 backend.hcl 파일을 사용합니다

terraform {
  # S3 Backend 설정
  # 실제 값은 backend.hcl 파일에서 주입됩니다
  backend "s3" {
    # ┌─────────────────────────────────────────────────┐
    # │ 아래 값들은 backend.hcl 또는                     │
    # │ terraform init -backend-config 으로 주입됩니다   │
    # │                                                   │
    # │ backend 블록에서는 var.xxx 변수를 사용할 수       │
    # │ 없기 때문에, 별도 파일로 분리하는 것이            │
    # │ 베스트 프랙티스입니다.                             │
    # └─────────────────────────────────────────────────┘

    # bucket         = "버킷이름"          # backend.hcl에서 주입
    # key            = "state파일경로"     # backend.hcl에서 주입
    # region         = "리전"              # backend.hcl에서 주입
    # encrypt        = true                # backend.hcl에서 주입
    # dynamodb_table = "잠금테이블이름"    # backend.hcl에서 주입
  }
}

# ==========================================
# 참고: Backend를 직접 설정하는 방법 (대안)
# ==========================================
#
# backend.hcl을 사용하지 않고 직접 값을 넣을 수도 있습니다:
#
# terraform {
#   backend "s3" {
#     bucket         = "terraform-study-state-a1b2c3d4"
#     key            = "05-remote-state/terraform.tfstate"
#     region         = "ap-northeast-2"
#     encrypt        = true
#     dynamodb_table = "terraform-study-terraform-lock"
#   }
# }
#
# 하지만 이 방법은:
# - 환경별로 다른 버킷을 사용할 때 코드를 수정해야 함
# - 버킷 이름이 하드코딩되어 유연성이 떨어짐
# → backend.hcl 방식을 권장합니다

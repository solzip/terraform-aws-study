# ==========================================
# backend.hcl - Backend 설정 파일
# ==========================================
#
# 이 파일은 backend.tf의 "s3" backend에 주입되는 설정 값입니다.
#
# 왜 별도 파일로 분리하는가?
# - backend 블록 안에서는 Terraform 변수(var.xxx)를 사용할 수 없음
# - 환경별로 다른 backend.hcl 파일을 만들어 전환 가능
#   예: backend-dev.hcl, backend-prod.hcl
# - .gitignore에 추가하여 환경별 설정을 로컬에서만 관리 가능
#
# 사용법:
#   terraform init -backend-config=backend.hcl
#
# 주의사항:
# - backend-setup/을 먼저 실행하여 S3 버킷과 DynamoDB 테이블을 생성하세요
# - 아래 bucket 값을 backend-setup의 output으로 나온 실제 버킷 이름으로 변경하세요

# State 파일을 저장할 S3 버킷 이름
# backend-setup에서 생성된 버킷 이름을 입력하세요
# 예: terraform-study-state-a1b2c3d4
bucket = "terraform-study-state-CHANGE-ME"

# S3 버킷 내 State 파일의 저장 경로 (키)
# 여러 프로젝트가 같은 버킷을 사용할 수 있으므로
# 프로젝트별로 고유한 경로를 지정합니다
key = "05-remote-state/terraform.tfstate"

# S3 버킷이 위치한 AWS 리전
region = "ap-northeast-2"

# State 파일 암호화 활성화
# S3에 저장될 때 자동으로 암호화됩니다
encrypt = true

# State 잠금에 사용할 DynamoDB 테이블 이름
# backend-setup에서 생성된 테이블 이름을 입력하세요
# 예: terraform-study-terraform-lock
dynamodb_table = "terraform-study-terraform-lock"

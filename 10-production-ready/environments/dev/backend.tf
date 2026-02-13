# ==========================================
# dev 환경 Backend 설정
# ==========================================
#
# Backend란?
#   Terraform State 파일을 어디에 저장할지 결정합니다.
#   로컬 파일 대신 S3에 저장하면:
#     1. 팀원 간 State 공유 가능
#     2. State Lock으로 동시 수정 방지
#     3. 버전 관리 (S3 Versioning)
#     4. 암호화 (S3 Encryption)
#
# ⚠️ 사전 준비:
#   S3 버킷과 DynamoDB 테이블을 먼저 만들어야 합니다.
#   이것은 "닭이 먼저냐 달걀이 먼저냐" 문제입니다.
#   보통 별도의 "bootstrap" Terraform 프로젝트로 생성합니다.
#
# 학습 시 주의:
#   아래 설정은 예시입니다. 실제 사용하려면:
#   1. S3 버킷 이름을 본인 계정의 것으로 변경
#   2. DynamoDB 테이블 생성
#   3. 주석 해제 후 terraform init 실행

terraform {
  # ------------------------------------------
  # S3 Backend (주석 해제하여 사용)
  # ------------------------------------------
  # backend "s3" {
  #   # State 파일을 저장할 S3 버킷
  #   # 버킷 이름은 전 세계적으로 고유해야 합니다
  #   bucket = "your-terraform-state-bucket"
  #
  #   # State 파일 경로 (환경별로 분리)
  #   # dev/staging/prod 각각 다른 키를 사용합니다
  #   key = "dev/terraform.tfstate"
  #
  #   # S3 버킷이 위치한 리전
  #   region = "ap-northeast-2"
  #
  #   # State Lock용 DynamoDB 테이블
  #   # 동시에 두 사람이 terraform apply를 실행하는 것을 방지합니다
  #   dynamodb_table = "terraform-state-lock"
  #
  #   # State 파일 암호화 (보안 필수)
  #   encrypt = true
  # }
}

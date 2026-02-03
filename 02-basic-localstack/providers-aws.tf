
# 실제 AWS 환경용 Provider 설정 (참고용)
#
# 이 파일은 실제 AWS에 배포할 때 사용하는 Provider 설정입니다.
# LocalStack 대신 실제 AWS를 사용하려면:
# 1. providers-localstack.tf 파일 이름을 변경 또는 삭제
# 2. 이 파일의 이름을 providers.tf로 변경
# 3. AWS 자격증명 설정 (aws configure)
# 4. terraform init 다시 실행

# ==========================================
# 실제 AWS Provider 설정
# ==========================================

# 주석 해제하여 사용:
# provider "aws" {
#   # AWS 리전 설정
#   region = var.aws_region
#
#   # AWS 자격증명은 다음 순서로 자동 감지됩니다:
#   # 1. 환경 변수 (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
#   # 2. ~/.aws/credentials 파일
#   # 3. ~/.aws/config 파일
#   # 4. IAM Role (EC2 인스턴스에서 실행 시)
#
#   # 모든 리소스에 자동으로 추가될 태그
#   default_tags {
#     tags = {
#       Project     = var.project_name
#       Environment = var.environment
#       ManagedBy   = "Terraform"
#       Branch      = "02-basic-localstack"
#     }
#   }
# }

# ==========================================
# LocalStack vs 실제 AWS 전환 방법
# ==========================================
#
# 방법 1: 파일 이름 변경 (권장)
# ------------------------------------------------
# LocalStack 사용 시:
#   - providers-localstack.tf (활성화)
#   - providers-aws.tf (비활성화/참고용)
#
# 실제 AWS 사용 시:
#   - providers-localstack.tf -> providers-localstack.tf.bak (백업)
#   - providers-aws.tf -> providers.tf (활성화)
#   - terraform init -reconfigure
#   - terraform plan
#   - terraform apply
#
# 명령어:
# $ mv providers-localstack.tf providers-localstack.tf.bak
# $ mv providers-aws.tf providers.tf
# $ terraform init -reconfigure
#
# ------------------------------------------------
#
# 방법 2: 조건부 설정 사용 (고급)
# ------------------------------------------------
# 환경 변수로 전환:
#
# export TF_VAR_use_localstack=false  # 실제 AWS
# export TF_VAR_use_localstack=true   # LocalStack
#
# 단, 이 경우 providers-localstack.tf를 수정해야 합니다.
#
# ------------------------------------------------
#
# 방법 3: Terraform Workspace 사용 (프로덕션)
# ------------------------------------------------
# Workspace로 환경 분리:
#
# $ terraform workspace new localstack
# $ terraform workspace new aws
#
# $ terraform workspace select localstack  # LocalStack 사용
# $ terraform workspace select aws         # 실제 AWS 사용
#
# 단, 이 경우 backend 설정도 필요합니다.

# ==========================================
# 주의사항
# ==========================================
#
# 실제 AWS 사용 시:
#
# 1. 비용 발생
#    - EC2 인스턴스는 실제로 실행되어 비용이 발생합니다
#    - 프리티어: t2.micro는 750시간/월 무료
#    - 실습 후 반드시 terraform destroy로 정리하세요!
#
# 2. 보안
#    - AWS 자격증명을 코드에 하드코딩하지 마세요
#    - terraform.tfvars 파일을 Git에 커밋하지 마세요
#    - IAM 최소 권한 원칙 적용
#
# 3. 리전 선택
#    - ap-northeast-2 (서울): 한국 사용자에게 가장 빠름
#    - us-east-1 (버지니아): 가장 저렴하지만 레이턴시 높음
#    - 프리티어는 모든 리전에서 동일하게 적용
#
# 4. 리소스 정리
#    - terraform destroy로 모든 리소스 삭제
#    - AWS Console에서 수동 확인
#    - AWS Billing Dashboard에서 비용 확인

# ==========================================
# 실제 AWS와 LocalStack의 차이점
# ==========================================
#
# LocalStack (개발/테스트):
# ✅ 완전 무료
# ✅ 빠른 리소스 생성/삭제 (수 초)
# ✅ 오프라인 가능
# ✅ 무제한 실습
# ❌ 실제 서버 실행 안 됨 (메타데이터만)
# ❌ 일부 AWS 기능 미지원
# ❌ Public IP로 실제 접속 불가
#
# 실제 AWS (프로덕션):
# ✅ 완전한 AWS 기능
# ✅ 실제 서버 실행
# ✅ Public IP로 접속 가능
# ✅ 프로덕션 환경 구축 가능
# ❌ 비용 발생
# ❌ 리소스 생성 시간 오래 걸림 (수 분)
# ❌ 인터넷 필수
# ❌ 실수 시 큰 비용 발생 가능

# ==========================================
# 추천 학습 흐름
# ==========================================
#
# 1단계: LocalStack으로 연습
#    - providers-localstack.tf 사용
#    - 코드 작성 및 테스트
#    - Terraform 명령어 익히기
#    - 비용 걱정 없이 여러 번 실습
#
# 2단계: 실제 AWS로 검증
#    - providers-aws.tf로 전환
#    - 실제 환경에서 1-2회 테스트
#    - 웹 서버 접속 확인
#    - 즉시 terraform destroy로 정리
#
# 3단계: 실전 적용
#    - 프로젝트에 Terraform 적용
#    - 프로덕션 환경 구축

# ==========================================
# 빠른 전환 스크립트 (선택사항)
# ==========================================
#
# LocalStack으로 전환:
# $ ./switch-to-localstack.sh
#
# 실제 AWS로 전환:
# $ ./switch-to-aws.sh
#
# 스크립트 예시 (switch-to-aws.sh):
# #!/bin/bash
# mv providers-localstack.tf providers-localstack.tf.bak
# mv providers-aws.tf providers.tf
# terraform init -reconfigure
# echo "✅ Switched to AWS!"
#
# 스크립트 예시 (switch-to-localstack.sh):
# #!/bin/bash
# mv providers.tf providers-aws.tf
# mv providers-localstack.tf.bak providers-localstack.tf
# terraform init -reconfigure
# echo "✅ Switched to LocalStack!"
# Backend Setup - State 저장 인프라

이 디렉토리는 Terraform State를 원격으로 관리하기 위한 **Backend 인프라**를 생성합니다.

## 생성되는 리소스

1. **S3 Bucket** - State 파일 저장소
   - 버전 관리 활성화 (State 복구 가능)
   - AES-256 서버 측 암호화
   - 퍼블릭 접근 완전 차단

2. **DynamoDB Table** - State 잠금
   - 동시 작업 방지 (Locking)
   - 온디맨드 과금 (사용량 적음)

## 사용법

```bash
# 1. Backend 인프라 생성
cd backend-setup
terraform init
terraform apply

# 2. 출력된 값 확인
terraform output s3_bucket_name
terraform output dynamodb_table_name

# 3. 상위 디렉토리의 backend.hcl에 값 복사
```

## 주의사항

- 이 코드의 State는 **로컬에 저장**됩니다 (닭과 달걀 문제)
- 다른 인프라를 삭제한 **후에** 이 Backend를 삭제하세요
- `force_destroy = true`이므로 학습 후 쉽게 정리 가능

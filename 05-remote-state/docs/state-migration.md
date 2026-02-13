# State 마이그레이션 가이드

## State 마이그레이션이란?

Terraform State의 저장 위치를 변경하는 것을 "마이그레이션"이라고 합니다.

```
로컬 (terraform.tfstate)  →  원격 (S3 버킷)
```

기존에 로컬로 관리하던 State를 S3 원격 Backend로 옮기는 방법을 설명합니다.

## 시나리오 1: 로컬 → S3 마이그레이션

### 상황
- 01-basic에서 로컬 State로 인프라를 만들었는데
- 팀 협업을 위해 S3 Backend로 전환하고 싶을 때

### 절차

```bash
# 1. backend.tf 파일 추가 (또는 수정)
cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "project/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
EOF

# 2. Backend 마이그레이션 실행
# -migrate-state 옵션이 핵심!
terraform init -migrate-state

# Terraform이 물어봅니다:
# "Do you want to copy existing state to the new backend?"
# → "yes" 입력

# 3. 마이그레이션 확인
# S3에 State가 복사되었는지 확인
aws s3 ls s3://my-terraform-state-bucket/project/

# 4. 로컬 State 파일 삭제 (선택사항)
# S3에 정상적으로 복사된 것을 확인한 후 삭제
rm terraform.tfstate
rm terraform.tfstate.backup
```

### 주의사항
- `-migrate-state` 옵션을 빼먹으면 **새로운 빈 State**로 시작됩니다!
- 반드시 "yes"를 입력하여 기존 State를 복사하세요
- 마이그레이션 후 로컬 State 파일은 백업으로 남아있습니다

## 시나리오 2: S3 → 로컬 마이그레이션 (역방향)

### 상황
- S3 Backend를 사용하다가 다시 로컬로 돌아가고 싶을 때

### 절차

```bash
# 1. backend.tf의 backend "s3" 블록을 삭제하거나 주석 처리

# 2. 마이그레이션 실행
terraform init -migrate-state

# "Do you want to copy existing state to the new backend?"
# → "yes" 입력

# 3. 확인
# 로컬에 terraform.tfstate 파일이 생성되었는지 확인
ls -la terraform.tfstate
```

## 시나리오 3: S3 버킷 A → S3 버킷 B 마이그레이션

### 상황
- Backend 버킷을 변경해야 할 때

### 절차

```bash
# 1. backend.tf에서 bucket 값 변경
# bucket = "old-bucket" → bucket = "new-bucket"

# 2. 마이그레이션 실행
terraform init -migrate-state

# "yes" 입력하여 State 복사
```

## State 관련 유용한 명령어

```bash
# State에 등록된 리소스 목록 확인
terraform state list

# 특정 리소스의 상세 정보 확인
terraform state show aws_instance.web

# State에서 리소스 제거 (인프라는 유지, Terraform 관리에서만 제외)
terraform state rm aws_instance.web

# State를 다른 리소스 주소로 이동 (리팩토링 시)
terraform state mv aws_instance.web aws_instance.app

# State 파일을 로컬에 다운로드 (디버깅용)
terraform state pull > state-backup.json

# 로컬 파일로 State 덮어쓰기 (위험! 백업 후 사용)
terraform state push state-backup.json
```

## State 문제 해결

### 문제 1: State Lock이 해제되지 않음

```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

원인: 이전 terraform 명령이 비정상 종료되어 잠금이 남아있음

```bash
# 강제 잠금 해제 (주의: 다른 사람이 작업 중이 아닌지 반드시 확인!)
terraform force-unlock xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 문제 2: State가 실제 인프라와 불일치

```bash
# State를 실제 인프라와 동기화
terraform refresh

# 또는 Terraform 1.5 이후 권장 방법
terraform apply -refresh-only
```

### 문제 3: State 파일이 손상됨

```bash
# S3 버전 관리를 활성화했다면 이전 버전으로 복구 가능
aws s3api list-object-versions \
  --bucket my-terraform-state \
  --prefix project/terraform.tfstate

# 특정 버전으로 복구
aws s3api get-object \
  --bucket my-terraform-state \
  --key project/terraform.tfstate \
  --version-id "이전버전ID" \
  restored-state.json

# 복구된 State를 push
terraform state push restored-state.json
```

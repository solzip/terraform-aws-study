# 05-remote-state - 원격 State 관리

> 🟡 **난이도**: 중급 | **학습 시간**: 3시간

[← 메인 README로 돌아가기](https://github.com/solzip/terraform-aws-study) | [← 이전: 04-modules-basic](https://github.com/solzip/terraform-aws-study/tree/04-modules-basic)

## 📚 학습 목표

- ✅ Terraform State 파일의 역할과 중요성 이해
- ✅ S3 Backend로 State를 원격 저장소에 관리
- ✅ DynamoDB를 이용한 State Locking (동시 작업 방지)
- ✅ State 파일 암호화 (보안 강화)
- ✅ 팀 협업을 위한 State 공유 방법
- ✅ 로컬 State → 원격 State 마이그레이션

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Cloud                            │
│                                                         │
│  ┌─────────────────────┐  ┌──────────────────────────┐ │
│  │  S3 Bucket           │  │  DynamoDB Table           │ │
│  │  (State 저장소)       │  │  (State 잠금)             │ │
│  │                      │  │                           │ │
│  │  terraform.tfstate   │  │  LockID (잠금 키)         │ │
│  │  - 버전 관리 활성화  │  │  - terraform apply 중     │ │
│  │  - AES-256 암호화    │  │    다른 사람 변경 차단    │ │
│  └──────────┬───────────┘  └──────────┬───────────────┘ │
│             │                         │                  │
│             └────────┬────────────────┘                  │
│                      │                                   │
│              ┌───────▼────────┐                          │
│              │  Terraform CLI  │                         │
│              │  (로컬 실행)    │                         │
│              └────────────────┘                          │
│                      │                                   │
│              ┌───────▼────────┐                          │
│              │  AWS 리소스     │                         │
│              │  (VPC, EC2 등) │                          │
│              └────────────────┘                          │
└─────────────────────────────────────────────────────────┘
```

## 📁 프로젝트 구조

```
05-remote-state/
├── README.md                  # 현재 문서
├── backend-setup/             # 1단계: Backend 인프라 생성
│   ├── main.tf               # S3 버킷 + DynamoDB 테이블
│   ├── outputs.tf            # 버킷/테이블 이름 출력
│   └── README.md             # Backend 설정 가이드
├── main.tf                   # 2단계: 실제 인프라 (VPC, EC2)
├── variables.tf              # 변수 정의
├── outputs.tf                # 출력 값
├── versions.tf               # Terraform/Provider 버전
├── backend.tf                # S3 Backend 설정
├── backend.hcl               # Backend 설정 파일 (변수 분리)
└── docs/
    └── state-migration.md    # State 마이그레이션 가이드
```

## 🚀 실습 가이드

### 1단계: Backend 인프라 생성 (S3 + DynamoDB)

```bash
git checkout 05-remote-state
cd 05-remote-state          # 실습 코드는 브랜치와 같은 이름의 디렉토리 안에 있습니다

cd backend-setup
terraform init
terraform apply
# → S3 버킷과 DynamoDB 테이블이 생성됩니다

# 생성된 이름을 확인해 둡니다
terraform output
```

### 2단계: backend.hcl에 실제 이름 반영

`backend.hcl`의 `bucket` 값은 `CHANGE-ME` 플레이스홀더입니다.
S3 버킷 이름은 전 세계에서 유일해야 하므로 1단계에서 생성된 실제 이름으로 바꿔야 합니다.

```hcl
# backend.hcl
bucket = "terraform-study-state-a1b2c3d4"   # ← 1단계 output 값으로 교체
```

이 단계를 건너뛰면 3단계에서 `NoSuchBucket` 오류가 발생합니다.

### 3단계: 원격 Backend로 초기화

```bash
cd ..
terraform init -backend-config=backend.hcl
# → State가 S3에 저장되기 시작합니다
```

### 4단계: 인프라 배포

```bash
terraform plan
terraform apply
# → State가 로컬이 아닌 S3에 저장됩니다
```

### 5단계: State 잠금 확인

```bash
# 터미널 A에서 apply 실행 중
terraform apply

# 터미널 B에서 동시에 apply 시도하면
# Error: Error acquiring the state lock
# → DynamoDB가 동시 접근을 차단합니다!
```

### 6단계: 리소스 정리

```bash
# 인프라 먼저 삭제
terraform destroy

# Backend 인프라 삭제 (선택사항)
cd backend-setup
terraform destroy
```

## 💡 핵심 학습 포인트

### 1. 왜 원격 State가 필요한가?

| 구분 | 로컬 State | 원격 State (S3) |
|------|-----------|----------------|
| 저장 위치 | 내 PC의 terraform.tfstate | S3 버킷 |
| 팀 협업 | ❌ 공유 불가 | ✅ 팀원 모두 접근 |
| 동시 작업 | ❌ 충돌 위험 | ✅ DynamoDB 잠금 |
| 백업 | ❌ 수동 백업 | ✅ S3 버전 관리 |
| 보안 | ❌ 로컬 파일 | ✅ 암호화 + IAM |

### 2. Backend 설정 방법

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"     # State 저장 버킷
    key            = "terraform.tfstate"       # State 파일 경로
    region         = "ap-northeast-2"          # 버킷 리전
    encrypt        = true                      # 암호화 활성화
    dynamodb_table = "terraform-lock"          # 잠금 테이블
  }
}
```

### 3. Backend 설정 파일 분리 (backend.hcl)

```hcl
# backend.hcl - 환경별로 다른 설정 파일 사용 가능
bucket         = "my-terraform-state"
key            = "05-remote-state/terraform.tfstate"
region         = "ap-northeast-2"
encrypt        = true
dynamodb_table = "terraform-lock"
```

```bash
# 사용법
terraform init -backend-config=backend.hcl
```

## 🔧 베스트 프랙티스

### 1. S3 버킷 보안
- ✅ 버전 관리 활성화 (State 복구용)
- ✅ 서버 측 암호화 (AES-256)
- ✅ 퍼블릭 접근 차단
- ✅ IAM 정책으로 접근 제한

### 2. DynamoDB 테이블
- ✅ 파티션 키: `LockID` (문자열)
- ✅ 과금: 온디맨드 (소량 사용 시 저렴)

### 3. State 관리 규칙
- ⚠️ State 파일을 **절대** 수동 편집하지 마세요
- ⚠️ `terraform state` 명령으로만 조작
- ⚠️ Backend 변경 시 반드시 `terraform init -migrate-state`

## ✅ 학습 체크리스트

- [ ] State 파일의 역할 이해
- [ ] S3 Backend 설정 완료
- [ ] DynamoDB State Locking 동작 확인
- [ ] backend.hcl로 설정 분리
- [ ] 팀 협업 시나리오 이해
- [ ] State 마이그레이션 개념 이해
- [ ] 리소스 정리 완료

## 🔄 다음 단계

원격 State 관리를 마스터했습니다! 🎉

```bash
terraform destroy
cd backend-setup && terraform destroy
git checkout 06-security-basic
```

06-security-basic에서는:
- IAM Role 및 Policy 생성
- Secrets Manager 기초
- KMS 암호화 기초

[← 이전: 04-modules-basic](https://github.com/solzip/terraform-aws-study/tree/04-modules-basic) | [다음: 06-security-basic →](https://github.com/solzip/terraform-aws-study/tree/06-security-basic)

---

**작성일**: 2025-02-02
**난이도**: 🟡 중급
**학습 시간**: 3시간

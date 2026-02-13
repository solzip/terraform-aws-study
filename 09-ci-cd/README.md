# 09-ci-cd - CI/CD 파이프라인

## 학습 목표

GitHub Actions를 사용하여 Terraform 코드의
**검증, 계획, 배포를 자동화**하는 CI/CD 파이프라인을 구축합니다.

## 이 브랜치에서 배우는 내용

### 1. GitHub Actions 워크플로우
- YAML 기반 워크플로우 정의
- 트리거 조건 (push, pull_request, manual)
- Job과 Step의 구조
- 환경 변수와 Secrets 관리

### 2. Terraform 자동화
- `terraform fmt -check` : 코드 포맷 검증
- `terraform validate` : 문법 검증
- `terraform plan` : 변경 사항 미리보기
- `terraform apply` : 실제 배포

### 3. PR 기반 워크플로우
- Pull Request 생성 시 자동 Plan 실행
- Plan 결과를 PR 코멘트로 표시
- 승인 후 Apply 실행

### 4. 안전한 배포 전략
- Plan → Review → Approve → Apply
- 수동 승인 단계 (Environment Protection Rules)
- Destroy 워크플로우의 이중 확인

## CI/CD 파이프라인 흐름

```
개발자가 코드 수정
  │
  ▼
Git Push / PR 생성
  │
  ▼
┌─────────────────────────────────────────┐
│ GitHub Actions                          │
│                                         │
│  [validate.yml]                         │
│  ├── terraform fmt -check               │
│  ├── terraform init                     │
│  ├── terraform validate                 │
│  └── tflint (선택)                      │
│                                         │
│  [terraform-plan.yml]                   │
│  ├── terraform plan                     │
│  └── PR 코멘트에 Plan 결과 표시         │
│                                         │
│  [terraform-apply.yml] (수동/승인 후)   │
│  ├── terraform plan (재확인)            │
│  └── terraform apply                    │
│                                         │
│  [terraform-destroy.yml] (수동 실행만)  │
│  ├── 이중 확인                          │
│  └── terraform destroy                  │
└─────────────────────────────────────────┘
```

## 파일 구조

```
09-ci-cd/
├── README.md
├── .github/
│   └── workflows/
│       ├── validate.yml              # fmt + validate 검증
│       ├── terraform-plan.yml        # PR 시 Plan 실행
│       ├── terraform-apply.yml       # 승인 후 Apply
│       └── terraform-destroy.yml     # 수동 Destroy
├── scripts/
│   ├── validate.sh                   # 로컬 검증 스크립트
│   └── plan.sh                       # 로컬 Plan 스크립트
├── docs/
│   ├── ci-cd-setup.md                # CI/CD 초기 설정 가이드
│   └── github-actions-guide.md       # GitHub Actions 상세 가이드
├── main.tf                           # 예시 인프라 (VPC, EC2)
├── variables.tf
├── outputs.tf
└── versions.tf
```

## GitHub Actions 사전 준비

### 1. GitHub Secrets 설정
```
Repository Settings → Secrets and variables → Actions

필수 Secrets:
  AWS_ACCESS_KEY_ID      : IAM 사용자 Access Key
  AWS_SECRET_ACCESS_KEY  : IAM 사용자 Secret Key
  AWS_REGION             : ap-northeast-2 (서울)
```

### 2. Environment 설정 (선택)
```
Repository Settings → Environments → New environment

"production" 환경 생성:
  - Required reviewers: 승인자 지정
  - Wait timer: 배포 전 대기 시간
```

## 시작하기

```bash
git checkout 09-ci-cd

# 로컬 검증
cd 09-ci-cd
bash scripts/validate.sh

# GitHub에 Push하면 자동으로 워크플로우 실행
git push origin 09-ci-cd
```

## 비용

이 브랜치는 GitHub Actions 워크플로우 파일만 포함합니다.
실제 AWS 리소스 배포는 워크플로우를 통해 수동으로 실행해야 합니다.

- GitHub Actions: Public 리포지토리 무료 / Private 2,000분/월 무료
- AWS 리소스: 워크플로우로 배포한 리소스에 따라 과금

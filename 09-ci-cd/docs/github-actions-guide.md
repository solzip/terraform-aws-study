# GitHub Actions 기초 가이드

## 목차
1. [GitHub Actions란?](#1-github-actions란)
2. [핵심 개념](#2-핵심-개념)
3. [워크플로우 파일 구조](#3-워크플로우-파일-구조)
4. [이벤트 트리거](#4-이벤트-트리거)
5. [Jobs와 Steps](#5-jobs와-steps)
6. [실전 패턴](#6-실전-패턴)
7. [Terraform과 함께 사용하기](#7-terraform과-함께-사용하기)

---

## 1. GitHub Actions란?

### 한 줄 정의
```
GitHub Actions = GitHub에 내장된 CI/CD 자동화 도구
```

### 왜 GitHub Actions를 사용하는가?
```
기존 방식 (수동 배포):
  개발자가 코드 수정
  → 로컬에서 테스트
  → 서버에 접속
  → 수동으로 배포
  → 문제 발생하면 수동 롤백
  ❌ 실수 가능성 높음
  ❌ 시간 많이 소요
  ❌ 일관성 없음

GitHub Actions 방식 (자동 배포):
  개발자가 코드 수정 & Push
  → 자동으로 테스트 실행
  → 자동으로 코드 검증
  → 승인 후 자동 배포
  → 문제 발생하면 자동 알림
  ✅ 실수 방지
  ✅ 빠른 피드백
  ✅ 일관된 프로세스
```

### 다른 CI/CD 도구와 비교
```
┌─────────────────┬──────────┬───────────┬──────────┐
│     도구         │  설정     │  GitHub   │  비용     │
│                 │  난이도   │  통합도    │          │
├─────────────────┼──────────┼───────────┼──────────┤
│ GitHub Actions  │  쉬움    │  완벽     │  무료*   │
│ Jenkins         │  어려움  │  플러그인 │  서버비용 │
│ GitLab CI       │  보통    │  별도     │  무료*   │
│ CircleCI        │  보통    │  연동     │  유료     │
└─────────────────┴──────────┴───────────┴──────────┘
* 무료 한도 내에서
```

---

## 2. 핵심 개념

### 용어 정리
```
Workflow (워크플로우)
├── 자동화 프로세스 전체를 정의하는 YAML 파일
├── .github/workflows/ 디렉토리에 위치
└── 하나의 저장소에 여러 워크플로우 가능

Event (이벤트)
├── 워크플로우를 실행시키는 트리거
├── 예: push, pull_request, schedule, workflow_dispatch
└── 하나의 워크플로우에 여러 이벤트 설정 가능

Job (잡)
├── 워크플로우 내의 작업 단위
├── 각 Job은 별도의 가상 머신(Runner)에서 실행
├── 기본적으로 병렬 실행
└── needs로 순서 지정 가능

Step (스텝)
├── Job 내의 개별 명령
├── uses: 미리 만들어진 Action 사용
├── run: 직접 쉘 명령 실행
└── 순서대로 실행 (직렬)

Runner (러너)
├── 워크플로우를 실행하는 가상 머신
├── GitHub 제공: ubuntu-latest, windows-latest, macos-latest
└── Self-hosted: 자체 서버 사용 가능
```

### 실행 흐름
```
Event 발생 (예: Push)
    │
    ▼
Workflow 시작 (.github/workflows/xxx.yml)
    │
    ├── Job 1 (Runner 1에서 실행)
    │   ├── Step 1: Checkout
    │   ├── Step 2: Setup
    │   └── Step 3: Test
    │
    ├── Job 2 (Runner 2에서 실행) ← 병렬 가능
    │   ├── Step 1: Checkout
    │   └── Step 2: Build
    │
    └── Job 3 (needs: [Job 1, Job 2]) ← 순서 의존
        ├── Step 1: Checkout
        └── Step 2: Deploy
```

---

## 3. 워크플로우 파일 구조

### 기본 구조
```yaml
# ==========================================
# 워크플로우 이름 (GitHub UI에 표시됨)
# ==========================================
name: "My Workflow"

# ==========================================
# 트리거: 언제 실행할 것인가?
# ==========================================
on:
  push:
    branches: [main]

# ==========================================
# 잡: 무엇을 실행할 것인가?
# ==========================================
jobs:
  my-job:
    name: "My Job"
    runs-on: ubuntu-latest    # 실행 환경

    steps:
      # Step 1: 코드 가져오기
      - name: Checkout
        uses: actions/checkout@v4

      # Step 2: 명령 실행
      - name: Run Tests
        run: echo "Hello World"
```

### 파일 위치
```
프로젝트 루트/
└── .github/
    └── workflows/
        ├── validate.yml       # 검증 워크플로우
        ├── terraform-plan.yml # Plan 워크플로우
        ├── terraform-apply.yml # Apply 워크플로우
        └── terraform-destroy.yml # Destroy 워크플로우

⚠️ 반드시 .github/workflows/ 경로에 위치해야 합니다!
   다른 위치에 있으면 GitHub가 인식하지 못합니다.
```

---

## 4. 이벤트 트리거

### 자주 사용하는 이벤트

#### push - 코드 Push 시 실행
```yaml
on:
  push:
    branches: [main]           # main 브랜치에 Push할 때만
    paths:                      # 특정 경로가 변경될 때만
      - "09-ci-cd/**"
      - "!09-ci-cd/docs/**"    # docs 변경은 제외 (!)
```

#### pull_request - PR 이벤트 시 실행
```yaml
on:
  pull_request:
    branches: [main]           # main으로의 PR
    types:                      # PR 이벤트 유형
      - opened                 # PR 생성 시
      - synchronize            # PR에 새 커밋 Push 시
      - reopened               # PR 재오픈 시
```

#### workflow_dispatch - 수동 실행
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: "배포 환경 선택"
        required: true
        type: choice           # 드롭다운 선택
        options:
          - dev
          - staging
          - prod
      confirm:
        description: "확인 문자 입력"
        required: true
        type: string           # 텍스트 입력
        default: "no"
```

#### schedule - 예약 실행 (Cron)
```yaml
on:
  schedule:
    # 매일 오전 9시 (KST) = UTC 0시에 실행
    - cron: "0 0 * * *"

# Cron 형식: 분 시 일 월 요일
#            ┬ ┬ ┬ ┬ ┬
#            │ │ │ │ └── 0-6 (일-토)
#            │ │ │ └──── 1-12
#            │ │ └────── 1-31
#            │ └──────── 0-23
#            └────────── 0-59
```

---

## 5. Jobs와 Steps

### Job 병렬 vs 순차 실행
```yaml
jobs:
  # Job A와 Job B는 병렬 실행
  job-a:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Job A"

  job-b:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Job B"

  # Job C는 A와 B가 모두 완료된 후 실행
  job-c:
    runs-on: ubuntu-latest
    needs: [job-a, job-b]      # 의존성 지정
    steps:
      - run: echo "Job C"
```

```
실행 순서:
    ┌──── Job A ────┐
    │               ├──→ Job C
    └──── Job B ────┘
    (병렬)           (순차)
```

### Step 상세 설명
```yaml
steps:
  # 1. Action 사용 (uses)
  #    다른 사람이 만든 재사용 가능한 Action
  - name: "코드 체크아웃"
    uses: actions/checkout@v4    # {소유자}/{이름}@{버전}

  # 2. 쉘 명령 실행 (run)
  - name: "스크립트 실행"
    run: |                       # 여러 줄 명령
      echo "첫 번째 명령"
      echo "두 번째 명령"

  # 3. 조건부 실행 (if)
  - name: "성공 시에만 실행"
    if: success()                # 이전 Step 성공 시
    run: echo "성공!"

  - name: "실패 시에만 실행"
    if: failure()                # 이전 Step 실패 시
    run: echo "실패 처리"

  - name: "항상 실행"
    if: always()                 # 성공/실패 무관
    run: echo "정리 작업"

  # 4. 환경 변수 사용
  - name: "환경 변수 사용"
    env:
      MY_VAR: "hello"
    run: echo "$MY_VAR"

  # 5. 출력값 전달 (Step 간)
  - name: "값 생성"
    id: my-step
    run: echo "result=hello" >> $GITHUB_OUTPUT

  - name: "값 사용"
    run: echo "${{ steps.my-step.outputs.result }}"
```

### 자주 사용하는 Actions
```
actions/checkout@v4
├── 저장소 코드를 Runner에 다운로드
└── 거의 모든 워크플로우의 첫 Step

hashicorp/setup-terraform@v3
├── Terraform CLI 설치
└── terraform_version으로 버전 지정

actions/github-script@v7
├── JavaScript로 GitHub API 호출
└── PR 코멘트 작성 등에 활용

actions/cache@v4
├── 파일/디렉토리 캐시
└── 빌드 속도 향상에 사용
```

---

## 6. 실전 패턴

### 패턴 1: 동시 실행 방지 (Concurrency)
```yaml
# 같은 PR에 여러 Push가 오면 이전 실행 취소
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# 왜 필요한가?
# PR에 3번 연속 Push하면:
#   Push 1 → 실행 시작 → 취소됨
#   Push 2 → 실행 시작 → 취소됨
#   Push 3 → 실행 시작 → 완료
# 불필요한 실행을 줄여 시간과 비용 절약
```

### 패턴 2: 조건부 실행 (if)
```yaml
# 환경별로 다른 동작
- name: "Prod 경고"
  if: github.event.inputs.environment == 'prod'
  run: echo "⚠️ 프로덕션 배포입니다!"

# PR 이벤트에서만 코멘트 작성
- name: "PR 코멘트"
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({...})
```

### 패턴 3: Job 간 데이터 전달
```yaml
jobs:
  plan:
    runs-on: ubuntu-latest
    # outputs로 다른 Job에 데이터 전달
    outputs:
      has_changes: ${{ steps.plan.outputs.exitcode }}
    steps:
      - id: plan
        run: terraform plan -detailed-exitcode
        continue-on-error: true

  apply:
    needs: plan
    runs-on: ubuntu-latest
    # plan Job의 output 사용
    if: needs.plan.outputs.has_changes == '2'
    steps:
      - run: terraform apply -auto-approve
```

### 패턴 4: Matrix 전략 (여러 환경 동시 실행)
```yaml
jobs:
  validate:
    strategy:
      matrix:
        environment: [dev, staging, prod]
    runs-on: ubuntu-latest
    steps:
      - run: |
          terraform plan \
            -var="environment=${{ matrix.environment }}"

# 결과:
# ├── validate (dev)     ← 병렬 실행
# ├── validate (staging) ← 병렬 실행
# └── validate (prod)    ← 병렬 실행
```

### 패턴 5: 실패 시 알림
```yaml
steps:
  - name: "Deploy"
    id: deploy
    run: terraform apply -auto-approve

  # 실패 시 Slack 알림 (예시)
  - name: "Notify on failure"
    if: failure() && steps.deploy.outcome == 'failure'
    run: |
      echo "배포 실패! 알림을 보냅니다."
      # curl로 Slack Webhook 호출 등
```

---

## 7. Terraform과 함께 사용하기

### 전체 CI/CD 파이프라인 흐름
```
개발자 코드 수정
    │
    ▼
git push (feature 브랜치)
    │
    ▼
PR 생성 → main 브랜치로
    │
    ├──→ [자동] Validate 워크플로우
    │    ├── terraform fmt -check
    │    ├── terraform init
    │    └── terraform validate
    │
    ├──→ [자동] Plan 워크플로우
    │    ├── terraform plan
    │    └── PR 코멘트에 결과 표시
    │
    ▼
코드 리뷰 & 승인
    │
    ▼
PR 머지 → main 브랜치
    │
    ▼
[수동] Apply 워크플로우
    ├── 환경 선택 (dev/staging/prod)
    ├── 확인 문자열 입력
    ├── terraform plan (재확인)
    └── terraform apply (실제 배포)
    │
    ▼
인프라 변경 완료!
```

### Terraform CI/CD의 핵심 원칙

#### 원칙 1: Plan은 자동, Apply는 수동
```
왜?
├── Plan은 읽기 전용 → 안전하므로 자동 실행
├── Apply는 실제 변경 → 위험하므로 수동 실행
└── "인프라는 신중하게 변경한다"
```

#### 원칙 2: State 파일 관리
```
로컬 State (학습용):
├── terraform.tfstate가 로컬에 저장
├── 한 명이 작업할 때만 가능
└── CI/CD에서는 backend=false로 실행

원격 State (실무용):
├── S3 + DynamoDB에 저장
├── 여러 명이 동시 작업 가능
├── State Lock으로 충돌 방지
└── 10-production-ready에서 학습 예정
```

#### 원칙 3: 환경별 분리
```
하나의 코드, 여러 환경:
├── 같은 main.tf, variables.tf 사용
├── 환경별 terraform.tfvars로 값만 다르게
├── 환경별 State 파일 분리
└── 환경별 GitHub Environment 보호 규칙
```

### 주의사항

#### Terraform State와 CI/CD
```
⚠️ 이 학습 프로젝트에서는 backend=false를 사용합니다.

이유:
├── S3 백엔드 설정 없이도 Plan/Validate 가능
├── 학습 목적에는 충분
└── State 관리는 10-production-ready에서 다룸

실무에서는:
├── 반드시 원격 backend (S3 + DynamoDB) 사용
├── State Lock 설정 필수
└── 환경별 State 파일 분리 필수
```

#### Secrets 보안
```
✅ 올바른 방법:
├── GitHub Secrets에 저장
├── 환경별 Secrets 분리
├── 최소 권한 IAM 사용
└── 정기적 키 로테이션

❌ 잘못된 방법:
├── 코드에 하드코딩
├── 환경 변수를 echo로 출력
├── 모든 환경에 같은 키 사용
└── Admin 권한 IAM 사용
```

---

## 참고 자료

### 공식 문서
```
GitHub Actions:
└── https://docs.github.com/en/actions

Terraform GitHub Actions:
└── https://github.com/hashicorp/setup-terraform

GitHub Actions 마켓플레이스:
└── https://github.com/marketplace?type=actions
```

### 이 프로젝트의 워크플로우 파일
```
.github/workflows/
├── validate.yml          # Step 1: 코드 검증
├── terraform-plan.yml    # Step 2: 변경 사항 확인
├── terraform-apply.yml   # Step 3: 실제 배포
└── terraform-destroy.yml # Step 4: 리소스 삭제
```

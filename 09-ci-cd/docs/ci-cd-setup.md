# CI/CD 환경 설정 가이드

## 목차
1. [사전 준비사항](#1-사전-준비사항)
2. [GitHub Secrets 설정](#2-github-secrets-설정)
3. [GitHub Environments 설정](#3-github-environments-설정)
4. [Branch Protection Rules](#4-branch-protection-rules)
5. [워크플로우 테스트](#5-워크플로우-테스트)
6. [트러블슈팅](#6-트러블슈팅)

---

## 1. 사전 준비사항

### AWS 계정 준비
```
필요한 것:
├── AWS 계정 (Free Tier 가능)
├── IAM 사용자 (프로그래밍 방식 액세스)
│   ├── Access Key ID
│   └── Secret Access Key
└── 필요한 IAM 권한
    ├── EC2 Full Access
    ├── VPC Full Access
    └── S3 (State 저장 시)
```

### CI/CD 전용 IAM 사용자 생성

> **왜 별도 사용자를 만드는가?**
> 개인 계정의 자격증명을 CI/CD에 사용하면 보안 위험이 있습니다.
> 최소 권한 원칙에 따라 CI/CD 전용 사용자를 만드는 것이 좋습니다.

#### Step 1: IAM 사용자 생성
```
AWS Console → IAM → Users → Add users
├── User name: terraform-ci-cd
├── Access type: ✅ Programmatic access
└── Next: Permissions
```

#### Step 2: 권한 정책 연결
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformCICD",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "s3:*",
        "iam:GetRole",
        "iam:PassRole",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-2"
        }
      }
    }
  ]
}
```

> **주의:** 위 정책은 학습용으로 넓은 범위의 권한을 부여합니다.
> 실제 프로덕션에서는 필요한 리소스와 액션만 허용해야 합니다.

#### Step 3: Access Key 저장
```
⚠️ Secret Access Key는 생성 시 한 번만 표시됩니다!
반드시 안전한 곳에 저장하세요.

절대 하면 안 되는 것:
├── ❌ 코드에 직접 입력
├── ❌ Git에 커밋
├── ❌ 메신저로 전송
└── ❌ 공개 저장소에 노출
```

---

## 2. GitHub Secrets 설정

### Secrets란?
```
GitHub Secrets = 암호화된 환경 변수
├── GitHub가 암호화하여 저장
├── 워크플로우 실행 시에만 복호화
├── 로그에 자동으로 마스킹 (***로 표시)
└── Repository 관리자만 설정/수정 가능
```

### 설정 방법

#### Step 1: Settings 접근
```
GitHub Repository → Settings 탭
→ 왼쪽 메뉴: Secrets and variables → Actions
→ "New repository secret" 버튼 클릭
```

#### Step 2: 필요한 Secrets 등록

| Secret Name | 값 | 설명 |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | AKIA... | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | wJalr... | AWS Secret Key |

```
등록 순서:
1. Name: AWS_ACCESS_KEY_ID
   Secret: (Access Key 붙여넣기)
   → "Add secret" 클릭

2. Name: AWS_SECRET_ACCESS_KEY
   Secret: (Secret Key 붙여넣기)
   → "Add secret" 클릭
```

### 워크플로우에서 사용하는 방법
```yaml
# 워크플로우 YAML에서 이렇게 참조합니다:
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

# secrets.XXX 형식으로 접근
# 로그에는 *** 로 마스킹되어 표시됩니다
```

> **보안 팁:** Secrets는 Fork된 저장소의 PR에서는 접근할 수 없습니다.
> 이것은 의도된 보안 기능입니다.

---

## 3. GitHub Environments 설정

### Environments란?
```
GitHub Environments = 배포 대상 환경 관리
├── 환경별 Secrets 분리 가능
├── 승인자(Reviewers) 지정 가능
├── 대기 시간(Wait timer) 설정 가능
├── 배포 가능한 브랜치 제한 가능
└── 배포 이력 자동 기록
```

### 환경 생성

#### Step 1: Environment 추가
```
Settings → Environments → "New environment"

생성할 환경:
├── dev        (개발 - 자유롭게 배포)
├── staging    (스테이징 - 제한적 배포)
└── prod       (프로덕션 - 엄격한 통제)
```

#### Step 2: 환경별 보호 규칙 설정

**dev 환경:**
```
Protection rules:
├── Required reviewers: (없음)
├── Wait timer: 0 minutes
└── Deployment branches: All branches
→ 개발 환경은 누구나 자유롭게 배포 가능
```

**staging 환경:**
```
Protection rules:
├── Required reviewers: 1명
├── Wait timer: 0 minutes
└── Deployment branches: Selected branches
│   └── main, staging/*
→ 리뷰어 1명의 승인 후 배포 가능
```

**prod 환경:**
```
Protection rules:
├── Required reviewers: 2명
├── Wait timer: 5 minutes (쿨다운 시간)
└── Deployment branches: Selected branches
│   └── main
→ 2명의 승인 + 5분 대기 후에만 배포 가능
```

### 환경별 Secrets (선택사항)
```
각 환경마다 다른 AWS 계정을 사용할 수 있습니다:

dev 환경:
├── AWS_ACCESS_KEY_ID: (dev 계정 키)
└── AWS_SECRET_ACCESS_KEY: (dev 계정 시크릿)

prod 환경:
├── AWS_ACCESS_KEY_ID: (prod 계정 키)
└── AWS_SECRET_ACCESS_KEY: (prod 계정 시크릿)
```

---

## 4. Branch Protection Rules

### 왜 브랜치 보호가 필요한가?
```
보호 없이 main 브랜치에 직접 Push하면:
├── 코드 리뷰 없이 변경 반영
├── CI 검증 없이 배포 가능
├── 실수로 인프라 삭제 위험
└── 누가 무엇을 변경했는지 추적 어려움

보호 규칙을 설정하면:
├── PR을 통해서만 변경 가능
├── CI 검증 통과 필수
├── 리뷰어 승인 필수
└── 변경 이력 자동 기록
```

### 설정 방법
```
Settings → Branches → "Add branch protection rule"

Branch name pattern: main

✅ Require a pull request before merging
   ├── Required approving reviews: 1
   └── Dismiss stale pull request approvals
        (새 Push가 있으면 기존 승인 무효화)

✅ Require status checks to pass before merging
   ├── Require branches to be up to date
   └── Status checks:
       └── "Terraform Plan" (워크플로우 이름)

✅ Require conversation resolution before merging
   (모든 리뷰 코멘트 해결 필수)

❌ Allow force pushes (절대 비활성화!)
❌ Allow deletions (절대 비활성화!)
```

---

## 5. 워크플로우 테스트

### Validate 워크플로우 테스트
```bash
# 1. 새 브랜치 생성
git checkout -b test/ci-cd-setup

# 2. Terraform 파일 수정 (작은 변경)
# 예: outputs.tf에 주석 추가

# 3. 커밋 & Push
git add .
git commit -m "test: validate workflow"
git push -u origin test/ci-cd-setup

# 4. PR 생성
# GitHub에서 "Compare & pull request" 클릭

# 5. Actions 탭에서 워크플로우 실행 확인
# "Terraform Validate" 워크플로우가 자동 실행됨
```

### Apply 워크플로우 테스트
```bash
# 1. GitHub → Actions 탭
# 2. 왼쪽에서 "Terraform Apply" 선택
# 3. "Run workflow" 클릭
# 4. 환경: dev 선택
# 5. confirm: yes 입력
# 6. "Run workflow" 클릭
```

### 테스트 체크리스트
```
□ Validate 워크플로우가 PR에서 자동 실행되는가?
□ Plan 결과가 PR 코멘트에 표시되는가?
□ Apply 워크플로우를 수동으로 실행할 수 있는가?
□ Destroy 워크플로우에서 "destroy" 확인이 동작하는가?
□ Secrets가 로그에 마스킹되어 표시되는가?
□ 환경 보호 규칙이 적용되는가?
```

---

## 6. 트러블슈팅

### 자주 발생하는 문제와 해결 방법

#### 문제 1: "Resource not accessible by integration"
```
원인: 워크플로우에 필요한 권한이 부족합니다.

해결:
permissions:
  contents: read
  pull-requests: write  ← PR 코멘트 작성에 필요

또는 Settings → Actions → General
→ "Read and write permissions" 선택
```

#### 문제 2: "Error: No valid credential sources found"
```
원인: AWS Secrets가 설정되지 않았거나 이름이 틀렸습니다.

확인사항:
1. Settings → Secrets → Actions에서 확인
2. Secret 이름이 정확한지 확인:
   - AWS_ACCESS_KEY_ID (O)
   - AWS_ACCESS_KEY (X) ← 이름 틀림
3. Secret 값에 앞뒤 공백이 없는지 확인
```

#### 문제 3: "Error: Terraform exited with code 1"
```
원인: Terraform 설정 오류

해결:
1. 로컬에서 먼저 테스트:
   bash scripts/validate.sh
2. 에러 메시지 확인 후 코드 수정
3. 다시 Push하면 워크플로우 자동 재실행
```

#### 문제 4: "Concurrency group cancel"
```
원인: 같은 PR에서 새 Push가 발생하여 이전 실행이 취소됨

이것은 정상 동작입니다!
concurrency 설정에 의해 의도된 것입니다:
  cancel-in-progress: true
→ 항상 최신 코드에 대해서만 실행
```

#### 문제 5: Apply가 실행되지 않음
```
원인: 확인 문자열이 올바르지 않음

확인사항:
1. confirm 입력란에 정확히 "yes"를 입력했는지 확인
2. 대소문자 구분 (Yes, YES는 동작하지 않음)
3. 앞뒤 공백 없이 입력
```

---

## 참고: 비용 관리

### GitHub Actions 무료 사용량
```
GitHub Free 플랜:
├── 월 2,000분 무료 (Linux runner)
├── 500MB 스토리지 무료
└── 공개 저장소는 무제한 무료!

시간 소요 예상:
├── Validate: ~1분
├── Plan: ~2분
├── Apply: ~3-5분
└── Destroy: ~3-5분

월 예상 사용량 (학습 기준):
├── 하루 5회 실행 × 3분 = 15분/일
├── 월 20일 × 15분 = 300분/월
└── 무료 한도(2,000분) 내에서 충분!
```

### AWS 비용 주의
```
⚠️ Apply 후 반드시 Destroy 실행!

비용이 발생할 수 있는 리소스:
├── EC2 인스턴스 (t2.micro는 Free Tier)
├── NAT Gateway (시간당 과금)
├── Elastic IP (미사용 시 과금)
└── S3 버킷 (미미한 비용)

안전한 학습 방법:
1. Apply로 리소스 생성
2. AWS Console에서 확인
3. 바로 Destroy로 삭제
4. 월말에 AWS 비용 확인
```

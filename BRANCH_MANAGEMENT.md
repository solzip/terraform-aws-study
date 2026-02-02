# Git 브랜치 관리 가이드

> 이 문서는 Terraform 학습 로드맵의 브랜치 전략과 작업 프로세스를 설명합니다.

## 📋 브랜치 전략 개요

각 브랜치는 독립적인 학습 주제를 다루며, `main` 브랜치는 전체 프로젝트 안내 역할을 합니다.

```
main (프로젝트 전체 가이드)
├── 01-basic
├── 02-basic-localstack
├── 03-multi-environment
├── 04-modules-basic
├── 05-remote-state
├── 06-security-basic
├── 07-security-advanced
├── 08-monitoring
├── 09-ci-cd
└── 10-production-ready
```

## 🚀 브랜치 생성 및 작업 프로세스

### 1단계: 현재 작업 완료 및 커밋

```bash
# 현재 브랜치에서 작업 중인 내용 확인
git status

# 변경사항 스테이징
git add .

# 커밋
git commit -m "feat: Complete 01-basic implementation

- Add VPC, Subnet, IGW configuration
- Add EC2 instance with Apache
- Add comprehensive documentation
- Add .gitignore for security"

# Push (원격 저장소가 있는 경우)
git push origin 01-basic
```

### 2단계: main 브랜치로 이동

```bash
# main 브랜치로 이동
git checkout main

# 원격에서 최신 변경사항 가져오기
git pull origin main
```

### 3단계: 새 브랜치 생성

```bash
# 01-basic에서 시작하여 02-basic-localstack 생성
git checkout -b 02-basic-localstack 01-basic

# 또는 main에서 새로 시작
git checkout -b 02-basic-localstack main
```

### 4단계: 브랜치별 작업

```bash
# 파일 생성 및 수정
# ...

# 변경사항 확인
git status
git diff

# 커밋
git add .
git commit -m "feat: Add LocalStack configuration

- Add docker-compose.yml for LocalStack
- Configure Terraform providers for local endpoints
- Add LocalStack setup documentation
- Update .gitignore for Docker files"
```

### 5단계: Push 및 PR (선택사항)

```bash
# 원격 저장소에 Push
git push -u origin 02-basic-localstack

# GitHub에서 Pull Request 생성 (선택사항)
# main ← 02-basic-localstack
```

## 📝 커밋 메시지 컨벤션

### 기본 형식
```
<type>: <subject>

<body>
```

### Type 종류
- `feat`: 새로운 기능 추가
- `docs`: 문서 추가/수정
- `fix`: 버그 수정
- `refactor`: 코드 리팩토링
- `chore`: 기타 작업 (빌드, 설정 등)
- `test`: 테스트 코드

### 브랜치별 첫 커밋 메시지 예시

#### 01-basic
```bash
git commit -m "feat: Implement Terraform AWS basic infrastructure

- Create VPC with public subnet
- Add EC2 instance with Apache web server
- Configure Security Groups for HTTP/SSH
- Add comprehensive documentation in docs/
- Add .gitignore for Terraform state files
- Add terraform.tfvars.example

Learning Objectives:
- Understand Terraform basic syntax (HCL)
- Learn AWS provider configuration
- Master resource creation and dependencies
- Understand state file management"
```

#### 02-basic-localstack
```bash
git commit -m "feat: Add LocalStack for local AWS development

- Install and configure LocalStack with Docker
- Modify Terraform providers for LocalStack endpoints
- Add docker-compose.yml for easy setup
- Create LocalStack-specific configuration
- Add comprehensive local development guide

Learning Objectives:
- Set up cost-free local AWS environment
- Understand LocalStack architecture
- Learn offline Terraform development
- Practice without AWS account"
```

#### 03-multi-environment
```bash
git commit -m "feat: Implement multi-environment infrastructure

- Separate dev/staging/prod configurations
- Add environment-specific tfvars files
- Implement Terraform workspace strategy
- Create environment directory structure
- Add backend configuration per environment

Learning Objectives:
- Understand environment separation strategies
- Learn workspace management
- Master variable file organization
- Implement environment-specific resource sizing"
```

## 🔄 브랜치 간 이동

### 기존 브랜치로 이동
```bash
# 특정 브랜치로 이동
git checkout 03-multi-environment

# 이전 브랜치로 돌아가기
git checkout -
```

### 작업 중인 변경사항이 있을 때
```bash
# 방법 1: Stash 사용
git stash
git checkout 다른-브랜치
git checkout 원래-브랜치
git stash pop

# 방법 2: 커밋 후 이동
git commit -m "WIP: Work in progress"
git checkout 다른-브랜치
```

## 🌿 브랜치 관리 명령어

### 브랜치 목록 확인
```bash
# 로컬 브랜치 목록
git branch

# 원격 브랜치 포함 모든 브랜치
git branch -a

# 브랜치 상세 정보
git branch -v
```

### 브랜치 병합
```bash
# main에 특정 브랜치 병합
git checkout main
git merge 01-basic

# Fast-forward 방지 (병합 커밋 생성)
git merge --no-ff 01-basic
```

### 브랜치 삭제
```bash
# 로컬 브랜치 삭제
git branch -d 01-basic

# 강제 삭제
git branch -D 01-basic

# 원격 브랜치 삭제
git push origin --delete 01-basic
```

## 📊 브랜치 비교

### 브랜치 간 차이 확인
```bash
# 두 브랜치 간 파일 차이
git diff 01-basic..02-basic-localstack

# 특정 파일만 비교
git diff 01-basic..02-basic-localstack -- main.tf

# 변경된 파일 목록만 보기
git diff --name-only 01-basic..02-basic-localstack
```

### 특정 브랜치의 파일 보기
```bash
# 다른 브랜치의 파일 내용 보기
git show 02-basic-localstack:main.tf

# 파일을 현재 브랜치로 가져오기
git checkout 02-basic-localstack -- main.tf
```

## 🎯 실전 시나리오

### 시나리오 1: 새 기능 브랜치 생성

```bash
# 1. 최신 main 가져오기
git checkout main
git pull origin main

# 2. 새 브랜치 생성
git checkout -b 04-modules-basic

# 3. 작업 진행...
# 파일 생성, 수정

# 4. 커밋
git add .
git commit -m "feat: Create reusable Terraform modules

- Add VPC module with configurable CIDR
- Add EC2 module with instance type options
- Add Security Group module
- Add comprehensive module documentation"

# 5. Push
git push -u origin 04-modules-basic
```

### 시나리오 2: 이전 브랜치에서 시작하여 새 브랜치 생성

```bash
# 이전 브랜치의 작업을 기반으로 시작
git checkout -b 05-remote-state 04-modules-basic

# 추가 작업 진행...
```

### 시나리오 3: 여러 브랜치 동시 관리

```bash
# Worktree 사용 (여러 브랜치를 동시에 작업)
git worktree add ../terraform-02-localstack 02-basic-localstack
git worktree add ../terraform-03-multi-env 03-multi-environment

# 각 디렉토리에서 독립적으로 작업 가능
cd ../terraform-02-localstack
# ...

# Worktree 제거
git worktree remove ../terraform-02-localstack
```

## 📚 브랜치별 README.md 관리

### main 브랜치
- 전체 학습 로드맵 제공
- 모든 브랜치 개요 설명
- 학습 순서 안내

### 각 학습 브랜치 (01-basic, 02-basic-localstack 등)
- 해당 브랜치의 구체적인 학습 내용
- 실습 단계별 가이드
- 트러블슈팅 정보

### 브랜치별 README 작성 템플릿

```markdown
# [브랜치명] - [주제]

> 🟢/🟡/🔴 **난이도**: 초급/중급/고급 | **학습 시간**: X시간

[← 메인 README로 돌아가기](../../)

## 📚 이 브랜치에서 배우는 것
...

## 🏗️ 생성되는 리소스
...

## 🚀 실습 시작하기
...

## 💡 핵심 학습 포인트
...

## 🐛 자주 발생하는 문제
...

## 🔄 다음 단계
...
```

## 🔍 학습 진행 상황 추적

### 완료한 브랜치 확인
```bash
# 병합된 브랜치 확인
git branch --merged main

# 아직 병합되지 않은 브랜치
git branch --no-merged main
```

### 학습 체크리스트 만들기
```bash
# 학습 진행률을 마크다운으로 관리
cat > LEARNING_PROGRESS.md << EOF
# 학습 진행률

- [x] 01-basic - Terraform 기초
- [ ] 02-basic-localstack - 로컬 개발 환경
- [ ] 03-multi-environment - 멀티 환경 관리
- [ ] 04-modules-basic - 모듈화 기초
- [ ] 05-remote-state - 원격 State 관리
- [ ] 06-security-basic - 보안 기초
- [ ] 07-security-advanced - 보안 심화
- [ ] 08-monitoring - 모니터링 & 로깅
- [ ] 09-ci-cd - CI/CD 파이프라인
- [ ] 10-production-ready - 프로덕션 레벨

## 학습 시작일
- 01-basic: 2025-02-02

## 학습 완료일
- 01-basic: 2025-02-02
EOF
```

## 🚨 주의사항

### 1. 민감한 정보 관리
```bash
# .gitignore가 제대로 설정되었는지 확인
cat .gitignore

# 커밋 전 확인
git status

# 실수로 커밋한 민감 정보 제거
git rm --cached terraform.tfvars
git commit -m "Remove sensitive file"
```

### 2. 브랜치 보호
```bash
# main 브랜치는 직접 수정하지 않기
# 항상 새 브랜치에서 작업 후 병합
```

### 3. 충돌 해결
```bash
# 병합 시 충돌 발생
git merge 02-basic-localstack

# 충돌 파일 확인
git status

# 파일 수정 후
git add .
git commit -m "Resolve merge conflict"
```

## 📖 추가 Git 리소스

- [Pro Git Book](https://git-scm.com/book/ko/v2)
- [Git Branching Model](https://nvie.com/posts/a-successful-git-branching-model/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**작성일**: 2025-02-02  
**버전**: 1.0.0
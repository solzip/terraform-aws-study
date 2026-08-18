# ⚡ 빠른 시작 가이드 (Quick Start)

> 5분 안에 Terraform AWS 학습을 시작하세요!

## 📋 필요한 것

- ✅ AWS 계정 (프리티어 가능)
- ✅ 터미널 (Terminal/CMD)
- ✅ 텍스트 에디터

> 💡 AWS 계정을 아직 만들지 않았다면 `01-basic` 대신 **`02-basic-localstack`**부터 시작하세요.
> Docker만 있으면 과금 없이 동일한 Terraform 문법을 실습할 수 있습니다.

---

## 🚀 3단계로 시작하기

### 1단계: 저장소 클론 (1분)

```bash
# 저장소 클론
git clone https://github.com/solzip/terraform-aws-study.git
cd terraform-aws-study

# 첫 번째 브랜치로 이동
git checkout 01-basic

# ⚠️ 실습 코드는 브랜치와 같은 이름의 디렉토리 안에 있습니다
cd 01-basic
```

> **꼭 기억하세요**: 모든 브랜치는 `<브랜치명>/` 하위 디렉토리에 `.tf` 파일을 두고 있습니다.
> 저장소 루트에서 `terraform init`을 실행하면 아무것도 찾지 못합니다.

### 2단계: 필수 도구 설치 (2분)

#### Terraform 설치

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Windows:**
```bash
choco install terraform
```

**설치 확인:**
```bash
terraform version
# Terraform v1.x.x 출력되면 성공
```

#### AWS CLI 설치 및 설정

**macOS:**
```bash
brew install awscli
```

**Windows:**
[AWS CLI 설치 프로그램 다운로드](https://aws.amazon.com/cli/)

**설정:**
```bash
aws configure
# AWS Access Key ID: [입력]
# AWS Secret Access Key: [입력]
# Default region: ap-northeast-2
# Default output format: json
```

### 3단계: 첫 인프라 배포 (2분)

```bash
# 현재 위치가 terraform-aws-study/01-basic 인지 확인
pwd

# 변수 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 초기화
terraform init

# 계획 확인
terraform plan

# 배포
terraform apply
# 'yes' 입력

# 접속 주소 확인 후 웹 브라우저로 접속
terraform output web_url
```

**축하합니다! 🎉 첫 번째 인프라를 배포했습니다!**

---

## 📚 다음 단계

### 학습 경로

```
현재 위치: 01-basic ✓

다음 단계:
├── 02-basic-localstack (로컬 환경)
├── 03-multi-environment (멀티 환경)
├── 04-modules-basic (모듈화)
└── ... (총 10단계)
```

### 학습 순서

1. **현재 브랜치 완료**
   ```bash
   # 리소스 정리
   terraform destroy
   ```

2. **다음 브랜치로 이동**
   ```bash
   # 저장소 루트로 올라온 뒤 브랜치를 전환합니다
   cd ..
   git checkout 02-basic-localstack
   cd 02-basic-localstack
   ```

3. **반복**

---

## 🎯 학습 목표 설정

### 초급 과정 (1주일)
- [ ] 01-basic
- [ ] 02-basic-localstack
- **목표**: Terraform 기본 이해

### 중급 과정 (2주일)
- [ ] 03-multi-environment
- [ ] 04-modules-basic
- [ ] 05-remote-state
- [ ] 06-security-basic
- **목표**: 실무 적용 가능

### 고급 과정 (3주일)
- [ ] 07-security-advanced
- [ ] 08-monitoring
- [ ] 09-ci-cd
- [ ] 10-production-ready
- **목표**: 프로덕션 레벨 구축

---

## 💡 유용한 팁

### 1. 학습 노트 작성
```bash
# 각 브랜치마다 학습 노트 작성
mkdir -p learning-notes
echo "# 오늘 배운 것" > learning-notes/$(date +%Y%m%d).md
```

### 2. 비용 절약
```bash
# 실습 후 반드시 리소스 삭제!
terraform destroy

# 또는 특정 리소스만 삭제
terraform destroy -target=aws_instance.web
```

### 3. 자주 사용하는 명령어
```bash
# 코드 검증
terraform validate

# 코드 포맷팅
terraform fmt

# 현재 리소스 확인
terraform state list

# 특정 리소스 상세 보기
terraform state show aws_instance.web

# 출력값 확인
terraform output
```

---

## 🔍 트러블슈팅

### 문제: AWS 자격증명 오류
```bash
Error: error configuring Terraform AWS Provider

해결:
aws configure
# Access Key와 Secret Key 다시 입력
```

### 문제: 포트 접속 안됨
```bash
웹 페이지가 안 열려요!

해결:
1. Security Group 확인
   terraform state show aws_security_group.web
   
2. 인스턴스 상태 확인
   aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
   
3. 5-10분 정도 기다리기 (인스턴스 부팅 시간)
```

### 문제: terraform.tfvars가 없어요
```bash
Error: No value for required variable

해결:
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # 값 수정
```

---

## 📖 추천 학습 순서

### Day 1: 환경 설정
- Terraform 설치
- AWS CLI 설정
- 01-basic 브랜치 클론

### Day 2-3: 기초 학습
- 01-basic 실습
- 문서 읽기
- 코드 이해하기

### Day 4-5: 로컬 환경
- 02-basic-localstack 실습
- Docker 설정
- LocalStack 이해

### Week 2: 중급 과정
- 멀티 환경 관리
- 모듈화
- 원격 State

### Week 3-4: 고급 과정
- 보안 강화
- 모니터링
- CI/CD

### Week 5-6: 프로덕션
- 전체 통합
- 고가용성 구축
- 최종 프로젝트

---

## 🎓 학습 자료

### 공식 문서
- [Terraform 공식 문서](https://www.terraform.io/docs)
- [AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### 커뮤니티
- [Terraform GitHub](https://github.com/hashicorp/terraform)
- [AWS 한국 사용자 그룹](https://www.facebook.com/groups/awskrug/)

### 책
- "Terraform: Up & Running" - Yevgeniy Brikman
- "Infrastructure as Code" - Kief Morris

---

## ⚡ 치트 시트

### 기본 명령어
```bash
# 초기화
terraform init

# 계획
terraform plan

# 적용
terraform apply

# 삭제
terraform destroy

# 검증
terraform validate

# 포맷
terraform fmt

# 출력
terraform output
```

### 유용한 플래그
```bash
# 자동 승인
terraform apply -auto-approve

# 특정 리소스만
terraform apply -target=aws_instance.web

# Plan 파일 저장
terraform plan -out=tfplan

# Plan 파일 실행
terraform apply tfplan
```

---

## 💬 도움이 필요하신가요?

- 📖 **상세 문서**: [README.md](README.md)
- 🔧 **브랜치 관리**: [BRANCH_MANAGEMENT.md](BRANCH_MANAGEMENT.md)
- 📁 **프로젝트 구조**: [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
- 📊 **학습 진행률**: [LEARNING_PROGRESS.md](LEARNING_PROGRESS.md)

---

## 🎉 시작할 준비 되셨나요?

```bash
# Let's Go!
cd terraform-aws-study
git checkout 01-basic
cd 01-basic
terraform init
terraform apply
```

**Happy Learning! 🚀**

---

**작성일**: 2025-02-02
**마지막 업데이트**: 2026-08-18
**예상 소요 시간**: 5분
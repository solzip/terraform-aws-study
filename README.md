# 🚀 Terraform AWS 완벽 학습 로드맵

> Terraform 기초부터 프로덕션 레벨까지 단계별 실습 프로젝트

## 📚 프로젝트 개요

이 저장소는 Terraform을 사용하여 AWS 인프라를 코드로 관리하는 방법을 **기초부터 고급까지 단계별로 학습**할 수 있도록 구성된 실습 프로젝트입니다.

각 브랜치는 독립적인 학습 주제를 다루며, 순차적으로 진행하면서 Terraform과 AWS 인프라 관리 능력을 체계적으로 향상시킬 수 있습니다.

## 🎯 전체 학습 목표

- ✅ Terraform 기본 문법 및 워크플로우 마스터
- ✅ AWS 주요 서비스 인프라 구축 능력 습득
- ✅ 로컬 개발 환경 구축 (LocalStack)
- ✅ 멀티 환경 관리 전략 수립
- ✅ 모듈화를 통한 코드 재사용성 향상
- ✅ 원격 State 관리 및 팀 협업 방법
- ✅ AWS 보안 Best Practices 적용
- ✅ 모니터링 및 로깅 시스템 구축
- ✅ CI/CD 파이프라인 자동화
- ✅ 프로덕션 레벨 인프라 설계 및 구현

## 📋 필수 요구사항

### 소프트웨어
- Terraform 1.0 이상
- AWS CLI 2.x
- Git 2.x
- Docker & Docker Compose (LocalStack용)
- 코드 에디터 (VSCode, IntelliJ 등)

### AWS 계정
- AWS 계정 (프리티어 가능)
- IAM 사용자 자격증명 (Access Key, Secret Key)
- 적절한 IAM 권한

### 권장 지식
- 기본적인 Linux 명령어
- Git 기초 사용법
- AWS 기본 개념 이해

## 🗺️ 학습 로드맵

### 난이도별 구분
- 🟢 **초급**: Terraform 및 AWS 기초
- 🟡 **중급**: 실무 적용 가능한 구조
- 🔴 **고급**: 프로덕션 레벨 구성

---

## 📖 브랜치별 학습 내용

### 🟢 1. `01-basic` - Terraform 기초
**현재 브랜치** | **학습 시간**: 2-3시간

#### 학습 내용
- Terraform 기본 문법 (HCL)
- Provider 설정 및 사용
- 기본 리소스 생성 (VPC, EC2, Security Group)
- Variables와 Outputs 활용
- State 파일 이해

#### 생성 리소스
- VPC (10.0.0.0/16)
- Public Subnet
- Internet Gateway
- EC2 Instance (t2.micro)
- Security Group

#### 시작하기
```bash
git checkout 01-basic
terraform init
terraform plan
terraform apply
```

📚 **상세 문서**: [브랜치 README](../../tree/01-basic)

---

### 🟢 2. `02-basic-localstack` - 로컬 개발 환경
**다음 브랜치** | **학습 시간**: 2시간

#### 학습 내용
- LocalStack 설치 및 설정
- Docker Compose 구성
- 로컬 환경에서 AWS 서비스 시뮬레이션
- 비용 없이 Terraform 실습
- 오프라인 개발 환경 구축

#### 핵심 기술
- LocalStack
- Docker Compose
- AWS CLI Local 설정

#### 시작하기
```bash
git checkout 02-basic-localstack
docker-compose up -d
terraform init
terraform apply
```

📚 **상세 문서**: [브랜치 README](../../tree/02-basic-localstack)

---

### 🟡 3. `03-multi-environment` - 멀티 환경 관리
**학습 시간**: 3시간

#### 학습 내용
- Dev, Staging, Prod 환경 분리
- Workspace 활용
- 환경별 변수 관리
- tfvars 파일 전략
- 환경별 리소스 크기 조정

#### 핵심 개념
```
environments/
├── dev/      # 개발 환경 (t2.micro)
├── staging/  # 스테이징 (t2.small)
└── prod/     # 프로덕션 (t3.medium)
```

#### 시작하기
```bash
git checkout 03-multi-environment

# Dev 환경
cd environments/dev
terraform init
terraform apply

# Prod 환경
cd ../prod
terraform init
terraform apply
```

📚 **상세 문서**: [브랜치 README](../../tree/03-multi-environment)

---

### 🟡 4. `04-modules-basic` - 모듈화 기초
**학습 시간**: 4시간

#### 학습 내용
- 모듈 설계 원칙
- 재사용 가능한 모듈 생성
- 로컬 모듈 vs 원격 모듈
- 모듈 입출력 설계
- 모듈 버전 관리

#### 모듈 구조
```
modules/
├── vpc/              # VPC 모듈
├── ec2/              # EC2 모듈
├── security-group/   # Security Group 모듈
└── alb/              # Load Balancer 모듈
```

#### 시작하기
```bash
git checkout 04-modules-basic
terraform init
terraform apply
```

📚 **상세 문서**: [브랜치 README](../../tree/04-modules-basic)

---

### 🟡 5. `05-remote-state` - 원격 State 관리
**학습 시간**: 3시간

#### 학습 내용
- S3 Backend 설정
- DynamoDB State Locking
- State 암호화 (KMS)
- 팀 협업을 위한 State 공유
- State 마이그레이션

#### 핵심 구성
```hcl
backend "s3" {
  bucket         = "terraform-state-bucket"
  key            = "terraform.tfstate"
  region         = "ap-northeast-2"
  dynamodb_table = "terraform-lock"
  encrypt        = true
  kms_key_id     = "arn:aws:kms:..."
}
```

#### 시작하기
```bash
git checkout 05-remote-state

# 1. Backend 인프라 생성
cd backend-setup
terraform apply

# 2. Remote state 사용
cd ..
terraform init -backend-config=backend.hcl
```

📚 **상세 문서**: [브랜치 README](../../tree/05-remote-state)

---

### 🟡 6. `06-security-basic` - 보안 기초
**학습 시간**: 4시간

#### 학습 내용
- IAM Role 및 Policy 생성
- Secrets Manager 기초
- KMS 암호화 기초
- Security Group 최적화
- 보안 그룹 최소 권한 원칙

#### 핵심 리소스
- IAM Roles & Policies
- AWS Secrets Manager
- KMS Keys
- Security Groups (세밀한 제어)

#### 시작하기
```bash
git checkout 06-security-basic
terraform init
terraform apply
```

📚 **상세 문서**: [브랜치 README](../../tree/06-security-basic)

---

### 🔴 7. `07-security-advanced` - 보안 심화
**학습 시간**: 6시간

#### 학습 내용
- IAM 최소 권한 원칙 완벽 구현
- Secrets Manager 자동 로테이션
- KMS 키 로테이션 전략
- VPC Flow Logs 네트워크 모니터링
- AWS Config Rules
- GuardDuty 위협 탐지
- Security Hub 통합

#### 보안 체크리스트
- ✅ IAM 최소 권한 정책
- ✅ 암호화된 Secrets 저장
- ✅ KMS 키 자동 로테이션
- ✅ VPC Flow Logs 활성화
- ✅ 네트워크 트래픽 모니터링
- ✅ 보안 취약점 자동 스캔

#### 시작하기
```bash
git checkout 07-security-advanced
terraform init
terraform apply
```

📚 **상세 문서**: [브랜치 README](../../tree/07-security-advanced)

---

### 🔴 8. `08-monitoring` - 모니터링 & 로깅
**학습 시간**: 5시간

#### 학습 내용
- CloudWatch 메트릭 및 대시보드
- CloudWatch Alarms 설정
- SNS 알림 통합
- CloudWatch Logs
- CloudTrail 감사 로깅
- X-Ray 분산 추적

#### 모니터링 구성
```
monitoring/
├── cloudwatch/   # 메트릭 & 알람
├── sns/          # 알림
├── logs/         # 로그 수집
└── cloudtrail/   # 감사 로깅
```

#### 시작하기
```bash
git checkout 08-monitoring
terraform init
terraform apply
```

📚 **상세 문서**: [브랜치 README](../../tree/08-monitoring)

---

### 🔴 9. `09-ci-cd` - CI/CD 파이프라인
**학습 시간**: 5시간

#### 학습 내용
- GitHub Actions 워크플로우
- Terraform 자동화 (fmt, validate, plan)
- PR 기반 Plan 실행
- 승인 후 Apply
- 자동 테스팅
- Terraform Cloud 통합

#### CI/CD 워크플로우
```
Pull Request → Terraform Plan → Review → Approve → Terraform Apply
```

#### 시작하기
```bash
git checkout 09-ci-cd

# GitHub Actions가 자동으로 실행
# .github/workflows/ 확인
```

📚 **상세 문서**: [브랜치 README](../../tree/09-ci-cd)

---

### 🔴 10. `10-production-ready` - 프로덕션 레벨
**학습 시간**: 8시간

#### 학습 내용
- 고가용성 아키텍처 (Multi-AZ)
- Auto Scaling Group
- Application Load Balancer
- RDS Multi-AZ
- ElastiCache Redis Cluster
- Route53 DNS
- CloudFront CDN
- WAF (Web Application Firewall)

#### 프로덕션 아키텍처
```
Route53 → CloudFront → ALB → ASG (EC2) → RDS Multi-AZ
                                      → ElastiCache
```

#### 시작하기
```bash
git checkout 10-production-ready
terraform init
terraform apply

# 주의: 프로덕션 레벨 리소스는 비용이 발생합니다!
```

📚 **상세 문서**: [브랜치 README](../../tree/10-production-ready)

---

## 🚀 빠른 시작 가이드

### 1. 저장소 클론
```bash
git clone <repository-url>
cd terraform-aws-basic
```

### 2. 첫 번째 브랜치로 시작
```bash
# 기초부터 시작
git checkout 01-basic

# 문서 읽기
cat README.md

# 실습 시작
terraform init
terraform plan
terraform apply
```

### 3. 순차적 학습
```bash
# 현재 브랜치 완료 후
terraform destroy

# 다음 브랜치로 이동
git checkout 02-basic-localstack
```

## 📊 학습 진행률 트래킹

### 체크리스트
- [ ] 01-basic - Terraform 기초
- [ ] 02-basic-localstack - 로컬 개발 환경
- [ ] 03-multi-environment - 멀티 환경 관리
- [ ] 04-modules-basic - 모듈화 기초
- [ ] 05-remote-state - 원격 State 관리
- [ ] 06-security-basic - 보안 기초
- [ ] 07-security-advanced - 보안 심화
- [ ] 08-monitoring - 모니터링 & 로깅
- [ ] 09-ci-cd - CI/CD 파이프라인
- [ ] 10-production-ready - 프로덕션 레벨

### 학습 노트
각 브랜치 학습 후 개인 학습 노트를 작성하세요.

```bash
# 학습 노트 작성 예시
# 각 브랜치의 learning-notes/ 디렉토리 활용
```

## 💰 비용 가이드

### 프리티어로 가능한 브랜치
- ✅ 01-basic (t2.micro EC2)
- ✅ 02-basic-localstack (로컬 환경, 무료)
- ✅ 03-multi-environment (Dev 환경만)
- ✅ 04-modules-basic
- ✅ 05-remote-state (S3 소량)
- ✅ 06-security-basic

### 비용이 발생하는 브랜치
- ⚠️ 07-security-advanced (GuardDuty, Config)
- ⚠️ 08-monitoring (CloudWatch 유료)
- ⚠️ 09-ci-cd (GitHub Actions 무료 범위 내)
- ⚠️ 10-production-ready (NAT Gateway, ALB, RDS)

**💡 Tip**: 실습 후 반드시 `terraform destroy`로 리소스 삭제!

## 🔒 보안 주의사항

### Git에 절대 커밋하지 말 것
```gitignore
# .gitignore에 포함됨
*.tfstate
*.tfstate.*
terraform.tfvars
.terraform/
*.pem
*.key
```

### 보안 Best Practices
1. AWS 자격증명은 환경변수 사용
2. Secrets Manager로 민감 정보 관리
3. IAM 최소 권한 원칙
4. MFA 활성화
5. 정기적인 키 로테이션

## 🛠️ 유용한 명령어

### 모든 브랜치 확인
```bash
git branch -a
```

### 특정 브랜치의 파일만 보기
```bash
git show 05-remote-state:README.md
```

### 브랜치 간 변경사항 비교
```bash
git diff 01-basic..02-basic-localstack
```

### 학습 진행 상황 확인
```bash
# 완료한 브랜치 표시
git branch --merged main
```

## 📚 추가 학습 자료

### 공식 문서
- [Terraform 공식 문서](https://www.terraform.io/docs)
- [AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### 커뮤니티
- [Terraform GitHub](https://github.com/hashicorp/terraform)
- [AWS 한국 사용자 그룹](https://www.facebook.com/groups/awskrug/)

### 책 추천
- "Terraform: Up & Running" by Yevgeniy Brikman
- "Infrastructure as Code" by Kief Morris

## 🤝 기여하기

이 프로젝트를 개선하고 싶으시다면:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 라이선스

이 프로젝트는 학습 목적으로 작성되었습니다.

## 👥 작성자

- **메인 작성자**: solzip

## 💬 문의 및 피드백

- Issues: GitHub Issues 활용
- Discussions: GitHub Discussions 활용

---

## 🎓 학습 완료 후 다음 단계

모든 브랜치를 완료했다면:

1. ✅ **개인 프로젝트 적용**: 학습한 내용을 실제 프로젝트에 적용
2. ✅ **Terraform Associate 자격증 준비**: HashiCorp 공식 자격증
3. ✅ **고급 주제 탐구**:
    - Terraform Enterprise
    - Policy as Code (Sentinel)
    - CDK for Terraform
4. ✅ **다른 클라우드 Provider 학습**:
    - Azure (azurerm)
    - GCP (google)
    - Kubernetes (kubernetes)

---

**⭐ 이 프로젝트가 도움이 되었다면 Star를 눌러주세요!**

**마지막 업데이트**: 2025-02-02  
**버전**: 1.0.0

# 프로젝트 구조 가이드

> Terraform AWS 학습 프로젝트의 전체 파일 구조와 각 파일의 역할을 설명합니다.

## 📁 Main 브랜치 구조

```
terraform-aws-basic/               # 프로젝트 루트
├── README.md                      # 📘 전체 학습 로드맵 (메인 가이드)
├── BRANCH_MANAGEMENT.md           # 📗 Git 브랜치 관리 가이드
├── PROJECT_STRUCTURE.md           # 📕 현재 문서 (프로젝트 구조)
├── LEARNING_PROGRESS.md           # 📊 개인 학습 진행률
└── .gitignore                     # 🚫 Git 제외 파일 목록
```

### 파일별 설명

#### README.md
- **목적**: 프로젝트 전체 개요 및 학습 로드맵
- **포함 내용**:
    - 10개 브랜치 전체 소개
    - 각 브랜치별 학습 목표 및 내용
    - 난이도 및 예상 학습 시간
    - 빠른 시작 가이드
    - 비용 안내
- **대상**: 프로젝트를 처음 접하는 학습자

#### BRANCH_MANAGEMENT.md
- **목적**: Git 브랜치 전략 및 작업 프로세스
- **포함 내용**:
    - 브랜치 생성/삭제/이동 방법
    - 커밋 메시지 컨벤션
    - 브랜치 병합 전략
    - 실전 시나리오
- **대상**: Git을 사용하여 학습을 관리하는 방법을 알고 싶은 학습자

#### .gitignore
- **목적**: Git에 커밋되지 않아야 할 파일 지정
- **포함 내용**:
  ```gitignore
  # Terraform
  *.tfstate
  *.tfstate.*
  terraform.tfvars
  .terraform/
  .terraform.lock.hcl
  
  # IDE
  .idea/
  .vscode/
  *.iml
  
  # OS
  .DS_Store
  Thumbs.db
  
  # Logs
  *.log
  ```

---

## 📁 학습 브랜치 기본 구조

각 학습 브랜치는 다음과 같은 기본 구조를 가집니다:

```
브랜치명/
├── README.md                      # 📘 브랜치별 학습 가이드
├── docs/                          # 📚 상세 문서 디렉토리
│   ├── 01-setup.md               # 초기 설정
│   ├── 02-execution.md           # 실행 가이드
│   ├── 03-cleanup.md             # 정리 가이드
│   └── architecture.png          # 아키텍처 다이어그램
├── main.tf                        # 🏗️ 주요 리소스 정의
├── variables.tf                   # 🔧 입력 변수 선언
├── outputs.tf                     # 📤 출력 값 정의
├── versions.tf                    # 🔖 Terraform/Provider 버전
├── terraform.tfvars.example       # 📋 변수 값 예시
├── .gitignore                     # 🚫 Git 제외 파일
└── learning-notes/                # 📝 개인 학습 노트 (선택)
    └── notes.md
```

---

## 📖 브랜치별 특수 구조

### 01-basic
```
01-basic/
├── README.md
├── docs/
│   ├── 01-setup.md
│   ├── 02-execution.md
│   └── 03-cleanup.md
├── main.tf                        # VPC, EC2, Security Group
├── variables.tf                   # 기본 변수
├── outputs.tf                     # Public IP, VPC ID 등
├── versions.tf                    # AWS Provider ~> 5.0
└── terraform.tfvars.example
```

### 02-basic-localstack
```
02-basic-localstack/
├── README.md
├── docs/
│   └── localstack-setup.md
├── docker-compose.yml             # 🐳 LocalStack 설정
├── localstack/
│   ├── init-scripts/              # 초기화 스크립트
│   └── README.md
├── main.tf                        # LocalStack용 리소스
├── providers-localstack.tf        # LocalStack endpoints
├── providers-aws.tf               # AWS (참고용)
└── Makefile                       # 편의 명령어
```

### 03-multi-environment
```
03-multi-environment/
├── README.md
├── environments/                  # 🌍 환경별 설정
│   ├── dev/
│   │   ├── terraform.tfvars      # Dev 환경 변수
│   │   └── backend.tf            # Dev backend 설정
│   ├── staging/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── terraform.tfvars
│       └── backend.tf
├── main.tf                        # 공통 리소스 정의
├── variables.tf                   # 환경 변수
└── modules/                       # (간단한 모듈)
```

### 04-modules-basic
```
04-modules-basic/
├── README.md
├── modules/                       # 📦 재사용 가능한 모듈
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── security-group/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── main.tf                        # 모듈 호출
├── variables.tf
└── outputs.tf
```

### 05-remote-state
```
05-remote-state/
├── README.md
├── backend-setup/                 # 🗄️ Backend 인프라
│   ├── main.tf                   # S3 + DynamoDB 생성
│   ├── outputs.tf                # Bucket/Table 이름
│   └── README.md
├── backend.tf                     # S3 Backend 설정
├── backend.hcl                    # Backend 설정 파일
├── main.tf
└── docs/
    └── state-migration.md         # State 마이그레이션 가이드
```

### 06-security-basic
```
06-security-basic/
├── README.md
├── modules/
│   ├── iam/                       # 🔐 IAM 모듈
│   │   ├── roles.tf
│   │   ├── policies.tf
│   │   └── outputs.tf
│   ├── kms/                       # 🔑 KMS 모듈
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── secrets/                   # 🤐 Secrets Manager
│       ├── main.tf
│       └── outputs.tf
├── security.tf                    # 보안 리소스
└── docs/
    └── security-best-practices.md
```

### 07-security-advanced
```
07-security-advanced/
├── README.md
├── modules/
│   ├── security/
│   │   ├── secrets-manager/
│   │   │   ├── main.tf
│   │   │   └── rotation.tf       # 🔄 자동 로테이션
│   │   ├── kms/
│   │   │   └── key-rotation.tf
│   │   ├── iam-policies/
│   │   │   └── least-privilege.tf
│   │   └── vpc-flow-logs/
│   │       ├── main.tf
│   │       └── cloudwatch.tf
├── guardduty.tf                   # 🛡️ GuardDuty 설정
├── config-rules.tf                # ✅ AWS Config Rules
├── security-hub.tf                # 🔍 Security Hub
└── docs/
    ├── security-checklist.md
    └── compliance.md
```

### 08-monitoring
```
08-monitoring/
├── README.md
├── modules/
│   ├── monitoring/
│   │   ├── cloudwatch/
│   │   │   ├── metrics.tf
│   │   │   ├── alarms.tf
│   │   │   └── dashboards.tf
│   │   ├── sns/
│   │   │   └── notifications.tf
│   │   ├── logs/
│   │   │   └── log-groups.tf
│   │   └── cloudtrail/
│   │       └── audit-trail.tf
├── monitoring.tf
└── docs/
    ├── alerting-guide.md
    └── log-analysis.md
```

### 09-ci-cd
```
09-ci-cd/
├── README.md
├── .github/
│   └── workflows/                 # 🔄 GitHub Actions
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       ├── terraform-destroy.yml
│       └── validate.yml
├── scripts/
│   ├── validate.sh
│   └── plan.sh
└── docs/
    ├── ci-cd-setup.md
    └── github-actions-guide.md
```

### 10-production-ready
```
10-production-ready/
├── README.md
├── modules/
│   ├── alb/                       # ⚖️ Application Load Balancer
│   ├── asg/                       # 📈 Auto Scaling Group
│   ├── rds/                       # 🗃️ RDS Multi-AZ
│   ├── elasticache/               # 💾 ElastiCache
│   ├── route53/                   # 🌐 DNS
│   └── cloudfront/                # 🚀 CDN
├── production.tf
├── alb.tf
├── asg.tf
├── rds.tf
└── docs/
    ├── architecture.md
    ├── scaling-strategy.md
    └── disaster-recovery.md
```

---

## 📄 Terraform 파일별 역할

### main.tf
- **역할**: 주요 리소스 정의
- **포함 내용**: VPC, EC2, Security Group 등
- **특징**:
    - 가장 중요한 파일
    - 리소스 간 의존성 정의
    - 주석으로 상세 설명 포함

### variables.tf
- **역할**: 입력 변수 선언
- **포함 내용**:
    - 변수 이름, 타입, 기본값
    - 설명(description)
    - 검증 규칙(validation)
- **장점**: 코드 재사용성 향상

### outputs.tf
- **역할**: 출력 값 정의
- **포함 내용**:
    - Public IP, URL 등 중요 정보
    - 다른 모듈에서 참조할 값
- **사용처**:
    - `terraform output` 명령
    - 다른 모듈/프로젝트에서 참조

### versions.tf
- **역할**: Terraform 및 Provider 버전 관리
- **포함 내용**:
    - Terraform 최소 버전
    - Provider 버전 제약
    - Provider 기본 설정
- **중요성**: 팀원 간 동일한 환경 보장

### terraform.tfvars.example
- **역할**: 변수 값 예시
- **용도**:
    - 새 사용자 가이드
    - 민감 정보 없이 Git 커밋 가능
- **사용법**:
  ```bash
  cp terraform.tfvars.example terraform.tfvars
  # terraform.tfvars 수정
  ```

---

## 📚 docs/ 디렉토리 구조

### 표준 문서
```
docs/
├── 01-setup.md                    # 환경 설정
├── 02-execution.md                # 실행 가이드
├── 03-cleanup.md                  # 리소스 정리
├── architecture.png               # 아키텍처 다이어그램
├── troubleshooting.md             # 문제 해결
└── faq.md                         # 자주 묻는 질문
```

### 브랜치별 추가 문서
- **02-localstack**: `localstack-setup.md`
- **05-remote-state**: `state-migration.md`
- **06-security-basic**: `security-best-practices.md`
- **07-security-advanced**: `compliance.md`
- **08-monitoring**: `alerting-guide.md`, `log-analysis.md`
- **09-ci-cd**: `github-actions-guide.md`
- **10-production**: `scaling-strategy.md`, `disaster-recovery.md`

---

## 🔧 설정 파일

### .gitignore
```gitignore
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
.terraform.lock.hcl
override.tf
override.tf.json

# IDE
.idea/
.vscode/
*.iml
*.swp

# OS
.DS_Store
Thumbs.db

# Secrets
*.pem
*.key
secrets/

# Logs
*.log
crash.log
```

### Makefile (일부 브랜치)
```makefile
.PHONY: init plan apply destroy clean

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
```

---

## 📊 학습 자료 디렉토리

### learning-notes/ (선택사항)
```
learning-notes/
├── 01-basic-notes.md
├── 02-localstack-notes.md
├── 03-multi-env-notes.md
└── README.md                      # 학습 노트 가이드
```

**개인 학습 노트 예시**:
```markdown
# 01-basic 학습 정리

## 학습일: 2025-02-02

## 배운 내용
- Terraform 기본 명령어 (init, plan, apply, destroy)
- HCL 문법의 기초
- AWS VPC와 EC2의 관계

## 어려웠던 점
- Security Group 규칙 설정
- State 파일의 역할 이해

## 다음에 공부할 것
- Module 구조화
- Remote State 관리
```

---

## 🎯 파일 네이밍 컨벤션

### Terraform 파일
- `main.tf`: 주요 리소스
- `variables.tf`: 변수 선언
- `outputs.tf`: 출력 값
- `versions.tf`: 버전 관리
- `backend.tf`: Backend 설정
- `[서비스명].tf`: 특정 서비스 (예: `rds.tf`, `alb.tf`)

### 문서 파일
- `README.md`: 브랜치 메인 가이드
- `01-[주제].md`: 순서가 있는 문서
- `[주제]-guide.md`: 가이드 문서
- `architecture.png`: 다이어그램

---

## 💡 모범 사례

### 1. 파일 크기 관리
- `main.tf`가 200줄 이상이면 분리 고려
- 서비스별로 파일 분리 (예: `vpc.tf`, `ec2.tf`)

### 2. 주석 작성
```hcl
# 리소스의 목적과 이유 설명
resource "aws_vpc" "main" {
  # 프로덕션 환경을 위한 충분한 IP 주소 공간 확보
  cidr_block = "10.0.0.0/16"  # 65,536 IP addresses
  
  # DNS 호스트네임 활성화로 EC2 인스턴스 식별 용이
  enable_dns_hostnames = true
}
```

### 3. 변수 검증
```hcl
variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "환경은 dev, staging, prod 중 하나여야 합니다."
  }
}
```

---

**작성일**: 2025-02-02  
**버전**: 1.0.0
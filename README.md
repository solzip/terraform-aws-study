# Terraform AWS 학습 로드맵

> Terraform 기초부터 프로덕션 레벨까지, 10개 브랜치로 단계별 실습하는 학습 저장소

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-ap--northeast--2-232F3E?logo=amazonaws&logoColor=white)
![Branches](https://img.shields.io/badge/branches-10-blue)
![Docs](https://img.shields.io/badge/docs-Korean-lightgrey)

## 프로젝트 개요

이 저장소는 Terraform으로 AWS 인프라를 관리하는 방법을 **기초부터 프로덕션 수준까지 10단계로** 학습하도록 구성된 실습 프로젝트입니다.

- 각 단계는 **독립된 브랜치**로 분리되어 있어, 원하는 주제만 골라서 실습할 수 있습니다.
- 모든 `.tf` 파일에 **한국어 주석**이 달려 있어 코드를 읽으며 개념을 익힐 수 있습니다.
- 기본 리전은 `ap-northeast-2`(서울)이며, 대부분의 단계는 AWS 프리티어 범위에서 실습 가능합니다.

## 학습 로드맵 한눈에 보기

```
초급 (기초 다지기)
├── 01-basic              Terraform 기본 문법, VPC, EC2
├── 02-basic-localstack   LocalStack으로 로컬 실습 환경
│
중급 (실무 구조 학습)
├── 03-multi-environment  Dev/Staging/Prod 환경 분리
├── 04-modules-basic      모듈로 코드 재사용
├── 05-remote-state       S3 Backend + DynamoDB Lock
│
고급 (프로덕션 수준)
├── 06-security-basic     IAM, KMS, Secrets Manager
├── 07-security-advanced  GuardDuty, Config Rules, Security Hub
├── 08-monitoring         CloudWatch, CloudTrail, SNS 알림
├── 09-ci-cd              GitHub Actions CI/CD 파이프라인
└── 10-production-ready   모든 것의 종합 (모듈화 + 환경분리)
```

## 저장소 구조 규칙 (중요)

이 저장소는 **브랜치마다 같은 이름의 하위 디렉토리에 실습 코드가 들어 있습니다.**
`main`의 공통 가이드 문서는 모든 브랜치에 함께 존재합니다.

```
<브랜치 이름>          예: 01-basic
├── README.md          공통 문서 (모든 브랜치에 존재)
├── QUICKSTART.md
├── BRANCH_MANAGEMENT.md
├── PROJECT_STRUCTURE.md
├── LEARNING_PROGRESS.md
└── 01-basic/          ← 실습 코드는 이 디렉토리 안에 있습니다
    ├── README.md      해당 단계의 상세 가이드
    ├── docs/          단계별 심화 문서
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── versions.tf
```

따라서 브랜치를 전환한 뒤에는 **반드시 해당 디렉토리로 이동**해야 합니다.

```bash
git checkout 01-basic
cd 01-basic          # ← 이 단계를 빠뜨리면 terraform init이 동작하지 않습니다
terraform init
```

## 필수 요구사항

| 항목 | 버전 | 용도 |
|------|------|------|
| Terraform | >= 1.0 | 인프라 코드 도구 |
| AWS CLI | 2.x | AWS 자격증명 관리 |
| Git | 2.x | 브랜치 전환 |
| Docker | 최신 | LocalStack 실행 (02번 전용) |

- AWS 계정 (프리티어 가능) — 단, `02-basic-localstack`은 계정 없이 실습 가능
- IAM 사용자 자격증명 (Access Key, Secret Key)

## 빠른 시작

```bash
# 1. 저장소 클론
git clone https://github.com/solzip/terraform-aws-study.git
cd terraform-aws-study

# 2. 첫 번째 단계로 이동
git checkout 01-basic
cd 01-basic

# 3. 변수 파일 준비 (예제 파일이 있는 단계만)
cp terraform.tfvars.example terraform.tfvars

# 4. 실습 진행
terraform init
terraform plan
terraform apply

# 5. 실습 완료 후 리소스 삭제 (필수!)
terraform destroy

# 6. 다음 단계로 이동
cd .. && git checkout 02-basic-localstack
```

비용이 걱정된다면 `01-basic` 대신 **`02-basic-localstack`부터 시작**해도 좋습니다. Docker만 있으면 AWS 과금 없이 동일한 문법을 실습할 수 있습니다.

---

## 브랜치별 학습 내용

### 01-basic — Terraform 기초

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 초급 | 9 | HCL, Provider, Resource, Output |

Terraform의 기본 문법과 워크플로우를 배웁니다. VPC, Subnet, Internet Gateway, Security Group, EC2를 직접 생성하며 `init` → `plan` → `apply` → `destroy` 사이클을 익힙니다.

```bash
git checkout 01-basic && cd 01-basic
terraform init && terraform plan && terraform apply
```

**생성 리소스**: VPC, Public Subnet, IGW, Route Table, Security Group, EC2 (t2.micro)
**문서**: `docs/01-setup.md`, `docs/02-execution.md`, `docs/03-.cleanup.md`

---

### 02-basic-localstack — 로컬 개발 환경

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 초급 | 18 | LocalStack, Docker Compose, Provider 전환 |

AWS 비용 없이 로컬에서 Terraform을 실습하는 환경을 구축합니다. Docker Compose로 LocalStack을 띄우고 AWS 서비스를 시뮬레이션하며, 실제 AWS와 LocalStack 사이를 전환하는 스크립트까지 다룹니다.

```bash
git checkout 02-basic-localstack && cd 02-basic-localstack
docker-compose up -d
./switch-to-localstack.sh
terraform init && terraform apply
```

**핵심 파일**: `docker-compose.yml`, `providers-localstack.tf`, `providers-aws.tf`, `switch-to-*.sh`, `makefile`
**문서**: LocalStack 셋업, Docker 가이드, 트러블슈팅

---

### 03-multi-environment — 멀티 환경 관리

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 중급 | 15 | tfvars, environments, locals, validation |

하나의 코드베이스로 Dev/Staging/Prod 환경을 관리합니다. 환경별 `terraform.tfvars`로 변수를 분리하고, `locals`로 환경별 조건 분기를 처리하며, `web-app` 모듈로 공통 인프라를 캡슐화합니다.

```bash
git checkout 03-multi-environment && cd 03-multi-environment
terraform plan -var-file=environments/dev/terraform.tfvars
```

```
environments/
├── dev/      terraform.tfvars + backend.tf
├── staging/  terraform.tfvars + backend.tf
└── prod/     terraform.tfvars + backend.tf
modules/
└── web-app/  환경 공통 인프라 모듈
```

---

### 04-modules-basic — 모듈화 기초

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 중급 | 18 | module, source, 입출력 설계, 재사용 |

Terraform 모듈을 직접 설계하고 조합합니다. VPC, EC2, Security Group을 각각 모듈로 분리하고 `main.tf`에서 조립합니다. 모듈마다 자체 README가 있어 인터페이스(변수/출력) 설계를 함께 학습할 수 있습니다.

```bash
git checkout 04-modules-basic && cd 04-modules-basic
terraform init && terraform apply
```

```
modules/
├── vpc/              VPC + Subnet + IGW
├── ec2/              EC2 Instance
└── security-group/   Security Group
```

---

### 05-remote-state — 원격 State 관리

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 중급 | 11 | S3 Backend, DynamoDB Lock, State 암호화 |

팀 협업에 필수인 원격 State 관리를 배웁니다. Backend 인프라(S3 + DynamoDB)를 먼저 부트스트래핑한 뒤, 로컬 State를 원격으로 마이그레이션합니다.

```bash
git checkout 05-remote-state && cd 05-remote-state

# 1. Backend 인프라 생성
cd backend-setup && terraform init && terraform apply

# 2. 출력된 버킷/테이블 이름을 backend.hcl에 반영 (bucket = "...CHANGE-ME" 수정)

# 3. Remote State로 전환
cd .. && terraform init -backend-config=backend.hcl
```

**핵심 개념**: State Lock, State 암호화, `-backend-config` 분리, State 마이그레이션(`docs/state-migration.md`)

---

### 06-security-basic — 보안 기초

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 16 | IAM Role/Policy, KMS, Secrets Manager |

AWS 보안의 3대 축인 IAM, KMS, Secrets Manager를 Terraform으로 구성합니다. IAM Role과 Instance Profile 설계, 고객 관리형 KMS 키, Secrets Manager 기반 민감 정보 관리를 다룹니다. 진입점은 `main.tf`가 아니라 **`security.tf`** 입니다.

```bash
git checkout 06-security-basic && cd 06-security-basic
terraform init && terraform apply
```

```
modules/
├── iam/       Role, Policy, Instance Profile
├── kms/       Customer Managed Key, 키 정책
└── secrets/   Secrets Manager, 암호화 저장
```

---

### 07-security-advanced — 보안 심화

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 23 | GuardDuty, Config Rules, Security Hub, 자동 로테이션 |

AWS 관리형 보안 서비스를 종합 구성합니다. GuardDuty로 위협을 탐지하고, AWS Config로 규정 준수를 점검하며, Security Hub로 보안 현황을 통합합니다. Secrets 자동 로테이션과 VPC Flow Logs까지 포함합니다.

```bash
git checkout 07-security-advanced && cd 07-security-advanced
terraform init && terraform apply
```

**핵심 리소스**

- GuardDuty Detector (`guardduty.tf`)
- Config Recorder + Delivery Channel + 규칙 4종 (`config-rules.tf`)
  — EBS 암호화, SSH 제한, S3 퍼블릭 접근 차단, Root MFA
- Security Hub (`security-hub.tf`)
- 모듈: `iam-policies/`(최소 권한), `kms/`(키 로테이션), `secrets-manager/`(로테이션), `vpc-flow-logs/`

> 이 단계는 **과금이 발생**합니다. 실습 후 반드시 `terraform destroy` 하세요.

---

### 08-monitoring — 모니터링 & 로깅

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 18 | CloudWatch, CloudTrail, SNS, Dashboard |

인프라 모니터링과 로깅 시스템을 구축합니다. CloudWatch Metrics/Alarms/Dashboard로 실시간 관측, SNS로 알림 전송, CloudTrail로 API 감사 로깅을 설정합니다. 진입점은 **`monitoring.tf`** 입니다.

```bash
git checkout 08-monitoring && cd 08-monitoring
terraform init && terraform apply
```

```
modules/monitoring/
├── cloudwatch/   Metrics, Alarms, Dashboard
├── sns/          알림 토픽 (monitoring + critical)
└── cloudtrail/   API 감사 로깅, Root 로그인 탐지
```

> ⚠️ 현재 `monitoring.tf`가 `./modules/monitoring/logs` 모듈을 호출하지만 해당 모듈이 아직 커밋되어 있지 않아 `terraform init`이 실패합니다. [알려진 이슈](#알려진-이슈) 참고.

---

### 09-ci-cd — CI/CD 파이프라인

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 13 | GitHub Actions, Workflow, 자동 검증 |

GitHub Actions로 Terraform CI/CD 파이프라인을 구성합니다. PR 시 자동 검증/Plan, 수동 승인 기반 Apply/Destroy, 환경 보호 규칙과 동시 실행 방지를 다룹니다.

```bash
git checkout 09-ci-cd && cd 09-ci-cd
./scripts/validate.sh     # 로컬에서 fmt + init + validate
./scripts/plan.sh
```

```
09-ci-cd/.github/workflows/
├── validate.yml           Push/PR 자동: fmt + init + validate
├── terraform-plan.yml     PR 자동: plan 결과를 PR 코멘트로
├── terraform-apply.yml    수동: 환경 선택 + 확인 후 배포
└── terraform-destroy.yml  수동: "destroy" 입력 확인 후 삭제
```

> 워크플로우 파일이 저장소 루트가 아닌 `09-ci-cd/.github/` 아래에 있어 GitHub에서 자동 실행되지는 않습니다. 실제로 돌려보려면 `.github/`를 저장소 루트로 옮기세요. (학습용으로는 파일을 읽는 것만으로 충분합니다.)

---

### 10-production-ready — 프로덕션 레벨 종합

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 23 | 모듈 아키텍처, 환경 분리, S3 Backend, 보안 강화 |

01~09에서 배운 모든 것을 하나로 합칩니다. 모듈화된 아키텍처, 환경별 변수 분리, S3 원격 State, 보안 강화(SSH 차단, IAM Role, EBS 암호화), 상세 모니터링을 갖춘 완성형 코드입니다.

```bash
git checkout 10-production-ready && cd 10-production-ready
terraform init -backend-config=environments/dev/backend.tf
terraform apply -var-file=environments/dev/terraform.tfvars
```

```
main.tf (오케스트레이터)
├── module.vpc       VPC, Subnet(2 AZ), IGW, Route Table
├── module.security  Security Group, IAM Role/Instance Profile
└── module.ec2       EC2 (AZ 분산, EBS 암호화, User Data 템플릿)
```

| 환경 | VPC CIDR | 인스턴스 | 대수 | 상세 모니터링 |
|------|----------|----------|------|----------------|
| dev | 10.1.0.0/16 | t2.micro | 1 | ✗ |
| staging | 10.2.0.0/16 | t2.small | 2 | ✓ |
| prod | 10.0.0.0/16 | t3.medium | 3 | ✓ |

세 환경 모두 `allowed_ssh_cidrs = []`로 **SSH 인바운드를 차단**하고, 접속은 SSM Session Manager 방식을 전제로 합니다.

---

## 함께 보는 문서

| 문서 | 내용 |
|------|------|
| [QUICKSTART.md](QUICKSTART.md) | 도구 설치부터 첫 `apply`까지 5분 가이드 |
| [BRANCH_MANAGEMENT.md](BRANCH_MANAGEMENT.md) | 브랜치 전략, 커밋 컨벤션, 실전 시나리오 |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | 파일 구조와 각 파일의 역할 |
| [LEARNING_PROGRESS.md](LEARNING_PROGRESS.md) | 학습 진행률 체크리스트 (개인 기록용) |
| [BRANCH_README_TEMPLATE.md](BRANCH_README_TEMPLATE.md) | 새 학습 브랜치를 만들 때 쓰는 README 템플릿 |

## 학습 진행 체크리스트

- [ ] 01-basic — Terraform 기초 (VPC, EC2)
- [ ] 02-basic-localstack — 로컬 실습 환경 (Docker, LocalStack)
- [ ] 03-multi-environment — 환경 분리 (tfvars, locals)
- [ ] 04-modules-basic — 모듈 설계와 재사용
- [ ] 05-remote-state — S3 Backend + State Lock
- [ ] 06-security-basic — IAM, KMS, Secrets Manager
- [ ] 07-security-advanced — GuardDuty, Config, Security Hub
- [ ] 08-monitoring — CloudWatch, CloudTrail, SNS
- [ ] 09-ci-cd — GitHub Actions CI/CD
- [ ] 10-production-ready — 프로덕션 종합

## 비용 가이드

| 브랜치 | 비용 | 참고 |
|--------|------|------|
| 01-basic | Free Tier | t2.micro EC2 |
| 02-basic-localstack | 무료 | 로컬 Docker 환경 |
| 03-multi-environment | Free Tier | Dev 환경 기준 |
| 04-modules-basic | Free Tier | t2.micro EC2 |
| 05-remote-state | 거의 무료 | S3/DynamoDB 소량 사용 |
| 06-security-basic | Free Tier | IAM 무료, KMS 키당 소액 |
| 07-security-advanced | 소액 발생 | GuardDuty, Config, Security Hub 과금 |
| 08-monitoring | 소액 발생 | CloudWatch 상세 모니터링, CloudTrail |
| 09-ci-cd | 무료 | GitHub Actions 무료 한도 내 |
| 10-production-ready | Free Tier ~ 유료 | dev는 Free Tier, staging/prod는 과금 |

> 실습이 끝나면 반드시 `terraform destroy`로 리소스를 삭제하세요. 특히 07, 08, 10(staging/prod)은 방치 시 비용이 누적됩니다.

## 보안 주의사항

```
Git에 절대 커밋하지 말 것:
├── *.tfstate          State 파일 (인프라 정보 + 평문 시크릿 포함 가능)
├── *.tfstate.*        State 백업
├── .terraform/        Provider 바이너리
├── *.tfvars           실제 값이 담긴 변수 파일 (.example만 커밋)
├── *.pem / *.key      SSH 키
└── 실제 자격증명       Access Key, Secret Key
```

- AWS 자격증명은 `aws configure` 또는 환경변수(`AWS_PROFILE`)로 관리하세요.
- 위 항목은 [.gitignore](.gitignore)에 이미 등록되어 있습니다.

## 알려진 이슈

| 브랜치 | 내용 |
|--------|------|
| 08-monitoring | `monitoring.tf`가 `./modules/monitoring/logs`를 호출하지만 해당 모듈 디렉토리가 커밋되어 있지 않습니다. Log Group 모듈(application/system/access/error)을 추가해야 `terraform init`이 통과합니다. |
| 09-ci-cd | 워크플로우가 `09-ci-cd/.github/workflows/`에 있어 GitHub이 자동 실행하지 않습니다. 실제 구동하려면 저장소 루트로 옮겨야 합니다. |
| 05-remote-state | `backend.hcl`의 `bucket` 값이 `CHANGE-ME` 플레이스홀더입니다. `backend-setup` 실행 후 실제 버킷 이름으로 교체하세요. |

## 참고 자료

- [Terraform 공식 문서](https://www.terraform.io/docs)
- [AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [LocalStack 문서](https://docs.localstack.cloud/)

## 작성자

- **메인 작성자**: [solzip](https://github.com/solzip)

---

**마지막 업데이트**: 2026-08-18

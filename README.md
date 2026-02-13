# Terraform AWS 학습 로드맵

> Terraform 기초부터 프로덕션 레벨까지 단계별 실습 프로젝트

## 프로젝트 개요

이 저장소는 Terraform으로 AWS 인프라를 관리하는 방법을 **기초부터 고급까지 10단계로** 학습할 수 있도록 구성된 실습 프로젝트입니다.

각 브랜치가 독립적인 학습 주제를 다루며, 순서대로 진행하면 Terraform과 AWS 인프라 관리 능력을 체계적으로 키울 수 있습니다.

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

## 필수 요구사항

| 항목 | 버전 | 용도 |
|------|------|------|
| Terraform | >= 1.0 | 인프라 코드 도구 |
| AWS CLI | 2.x | AWS 자격증명 관리 |
| Git | 2.x | 브랜치 전환 |
| Docker | 최신 | LocalStack 실행 (02번) |

- AWS 계정 (프리티어 가능)
- IAM 사용자 자격증명 (Access Key, Secret Key)

---

## 브랜치별 학습 내용

### 01-basic - Terraform 기초

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 초급 | 9 | HCL, Provider, Resource, Output |

Terraform의 기본 문법과 워크플로우를 배웁니다. VPC, Subnet, Internet Gateway, Security Group, EC2를 직접 생성하며 `init` → `plan` → `apply` → `destroy` 사이클을 익힙니다.

```bash
git checkout 01-basic
terraform init && terraform plan && terraform apply
```

**생성 리소스**: VPC, Public Subnet, IGW, Route Table, Security Group, EC2 (t2.micro)

---

### 02-basic-localstack - 로컬 개발 환경

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 초급 | 18 | LocalStack, Docker Compose, 로컬 실습 |

AWS 비용 없이 로컬에서 Terraform을 실습하는 환경을 구축합니다. Docker Compose로 LocalStack을 실행하고, AWS 서비스를 시뮬레이션합니다. 실제 AWS와 LocalStack 간 전환 방법도 포함합니다.

```bash
git checkout 02-basic-localstack
docker-compose up -d
terraform init && terraform apply
```

**핵심 파일**: `docker-compose.yml`, `.env.example`, AWS/LocalStack 전환 가이드

---

### 03-multi-environment - 멀티 환경 관리

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 중급 | 15 | tfvars, environments, locals, validation |

하나의 Terraform 코드로 Dev/Staging/Prod 환경을 관리하는 방법을 배웁니다. 환경별 `terraform.tfvars`로 변수를 분리하고, `locals`로 환경별 조건 분기를 처리합니다.

```bash
git checkout 03-multi-environment
# Dev 환경
terraform plan -var-file=environments/dev/terraform.tfvars
```

**디렉토리 구조**:
```
environments/
├── dev/      terraform.tfvars + backend.tf
├── staging/  terraform.tfvars + backend.tf
└── prod/     terraform.tfvars + backend.tf
```

---

### 04-modules-basic - 모듈화 기초

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 중급 | 18 | module, source, 입출력, 재사용 |

Terraform 모듈을 설계하고 재사용하는 방법을 배웁니다. VPC, EC2, Security Group을 각각 모듈로 분리하고, `main.tf`에서 모듈을 조합하여 인프라를 구성합니다.

```bash
git checkout 04-modules-basic
terraform init && terraform apply
```

**모듈 구조**:
```
modules/
├── vpc/              VPC + Subnet + IGW
├── ec2/              EC2 Instance
└── security-group/   Security Group
```

---

### 05-remote-state - 원격 State 관리

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 중급 | 11 | S3 Backend, DynamoDB Lock, State 암호화 |

팀 협업에 필수인 원격 State 관리를 배웁니다. S3에 State 파일을 저장하고, DynamoDB로 동시 수정을 방지(Lock)합니다. Backend 인프라 부트스트래핑부터 State 마이그레이션까지 다룹니다.

```bash
git checkout 05-remote-state
# 1. Backend 인프라 생성
cd backend-setup && terraform apply
# 2. Remote State 사용
cd .. && terraform init -backend-config=backend.hcl
```

**핵심 개념**: State Lock, State 암호화, backend-config

---

### 06-security-basic - 보안 기초

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 16 | IAM Role/Policy, KMS, Secrets Manager |

AWS 보안의 3대 축인 IAM, KMS, Secrets Manager를 Terraform으로 구성합니다. IAM Role과 Policy 설계, KMS 키 생성과 암호화, Secrets Manager로 민감 정보를 안전하게 관리하는 방법을 배웁니다.

```bash
git checkout 06-security-basic
terraform init && terraform apply
```

**모듈 구조**:
```
modules/
├── iam/       Role, Policy, Instance Profile
├── kms/       Customer Managed Key, 키 정책
└── secrets/   Secrets Manager, 암호화 저장
```

---

### 07-security-advanced - 보안 심화

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 23 | GuardDuty, Config Rules, Security Hub, ABAC |

AWS 관리형 보안 서비스를 종합적으로 구성합니다. GuardDuty로 위협을 탐지하고, AWS Config로 규정 준수를 확인하며, Security Hub로 보안 현황을 통합 관리합니다. Lambda 기반 Secrets 자동 로테이션, ABAC 정책, Permission Boundary까지 다룹니다.

```bash
git checkout 07-security-advanced
terraform init && terraform apply
```

**핵심 리소스**: GuardDuty Detector, Config Recorder + 4 Rules, Security Hub + CIS/FSBP, Lambda Rotation, VPC Flow Logs

---

### 08-monitoring - 모니터링 & 로깅

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 18 | CloudWatch, CloudTrail, SNS, Dashboard |

인프라 모니터링과 로깅 시스템을 구축합니다. CloudWatch Metrics/Alarms/Dashboard로 실시간 모니터링, SNS로 알림 전송, CloudWatch Logs로 중앙 집중 로깅, CloudTrail로 API 감사 로깅을 설정합니다.

```bash
git checkout 08-monitoring
terraform init && terraform apply
```

**모듈 구조**:
```
modules/monitoring/
├── cloudwatch/   Metrics, Alarms, Dashboard (6위젯)
├── sns/          알림 토픽 (monitoring + critical)
├── logs/         Log Groups (application, system, access, error)
└── cloudtrail/   API 감사 로깅, Root 로그인 탐지
```

---

### 09-ci-cd - CI/CD 파이프라인

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 13 | GitHub Actions, Workflow, 자동 검증 |

GitHub Actions로 Terraform CI/CD 파이프라인을 구축합니다. PR 생성 시 자동 Validate/Plan, 수동 Apply/Destroy 워크플로우, 환경별 보호 규칙과 동시 실행 방지를 설정합니다.

```bash
git checkout 09-ci-cd
# GitHub Actions가 자동으로 실행됩니다
# .github/workflows/ 디렉토리 확인
```

**워크플로우**:
```
.github/workflows/
├── validate.yml          PR 시 자동: fmt + init + validate
├── terraform-plan.yml    PR 시 자동: plan 결과를 PR 코멘트에 표시
├── terraform-apply.yml   수동: 환경 선택 + 확인 후 배포
└── terraform-destroy.yml 수동: "destroy" 입력 확인 후 삭제
```

**로컬 스크립트**: `scripts/validate.sh`, `scripts/plan.sh`

---

### 10-production-ready - 프로덕션 레벨

| 난이도 | 파일 수 | 핵심 키워드 |
|--------|---------|-------------|
| 고급 | 23 | 모듈 아키텍처, 환경 분리, S3 Backend |

01~09에서 배운 모든 것을 종합하여 프로덕션 수준의 인프라를 구성합니다. 모듈화된 아키텍처, 환경별 변수 분리, S3 원격 State, 보안 강화(SSH 차단, IAM Role, EBS 암호화), 상세 모니터링을 갖춘 완성형 코드입니다.

```bash
git checkout 10-production-ready
cd environments/dev
terraform init && terraform apply
```

**아키텍처**:
```
main.tf (오케스트레이터)
├── module.vpc       VPC, Subnet, IGW, Route Table
├── module.security  Security Group, IAM Role/Profile
└── module.ec2       EC2 (AZ 분산, EBS 암호화, User Data)

environments/
├── dev/      t2.micro x1, 기본 모니터링
├── staging/  t2.small x2, 상세 모니터링
└── prod/     t3.medium x3, 상세 모니터링, SSH 차단
```

---

## 빠른 시작

```bash
# 1. 저장소 클론
git clone https://github.com/solzip/terraform-aws-study.git
cd terraform-aws-study

# 2. 첫 번째 브랜치로 시작
git checkout 01-basic

# 3. 각 브랜치의 README.md 읽기
# 4. 실습 진행
terraform init
terraform plan
terraform apply

# 5. 실습 완료 후 리소스 삭제
terraform destroy

# 6. 다음 브랜치로 이동
git checkout 02-basic-localstack
```

## 학습 진행 체크리스트

- [ ] 01-basic - Terraform 기초 (VPC, EC2)
- [ ] 02-basic-localstack - 로컬 실습 환경 (Docker, LocalStack)
- [ ] 03-multi-environment - 환경 분리 (tfvars, locals)
- [ ] 04-modules-basic - 모듈 설계와 재사용
- [ ] 05-remote-state - S3 Backend + State Lock
- [ ] 06-security-basic - IAM, KMS, Secrets Manager
- [ ] 07-security-advanced - GuardDuty, Config, Security Hub
- [ ] 08-monitoring - CloudWatch, CloudTrail, SNS
- [ ] 09-ci-cd - GitHub Actions CI/CD
- [ ] 10-production-ready - 프로덕션 종합

## 비용 가이드

| 브랜치 | 비용 | 참고 |
|--------|------|------|
| 01-basic | Free Tier | t2.micro EC2 |
| 02-basic-localstack | 무료 | 로컬 Docker 환경 |
| 03-multi-environment | Free Tier | Dev 환경 기준 |
| 04-modules-basic | Free Tier | t2.micro EC2 |
| 05-remote-state | 거의 무료 | S3 소량 사용 |
| 06-security-basic | Free Tier | IAM/KMS 기본 무료 |
| 07-security-advanced | 소액 발생 | GuardDuty, Config 과금 |
| 08-monitoring | 소액 발생 | CloudWatch 상세 모니터링 |
| 09-ci-cd | 무료 | GitHub Actions 무료 한도 내 |
| 10-production-ready | Free Tier ~ 소액 | 환경에 따라 상이 |

> 실습 후 반드시 `terraform destroy`로 리소스를 삭제하세요!

## 보안 주의사항

```
Git에 절대 커밋하지 말 것:
├── *.tfstate          State 파일 (인프라 정보 포함)
├── *.tfstate.*        State 백업
├── .terraform/        Provider 바이너리
├── *.pem / *.key      SSH 키
└── 실제 자격증명       Access Key, Secret Key
```

AWS 자격증명은 `aws configure` 또는 환경변수로 관리하세요.

## 참고 자료

- [Terraform 공식 문서](https://www.terraform.io/docs)
- [AWS Provider 문서](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [GitHub Actions 문서](https://docs.github.com/en/actions)

## 작성자

- **메인 작성자**: solzip

---

**마지막 업데이트**: 2026-02-12

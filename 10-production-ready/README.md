# 10-production-ready - 프로덕션 수준 인프라

> 🔴 **난이도**: 고급 | **학습 시간**: 8시간

[← 메인 README](https://github.com/solzip/terraform-aws-study) | [← 이전: 09-ci-cd](https://github.com/solzip/terraform-aws-study/tree/09-ci-cd)

## 학습 목표
이 모듈은 **01~09에서 배운 모든 것을 종합**하여
실제 프로덕션에 사용할 수 있는 수준의 Terraform 코드를 작성합니다.

## 핵심 개념

### 1. 모듈화된 아키텍처
```
modules/
├── vpc/       VPC, Public Subnet(2 AZ), IGW, Route Table
├── ec2/       EC2 Instance (count로 다중 생성, EBS 암호화, User Data)
└── security/  Security Group, IAM Role + Instance Profile(SSM)
```

### 2. 환경별 분리 (S3 Backend)
```
environments/
├── dev/       개발 환경 (최소 비용)
├── staging/   스테이징 환경 (Prod와 유사)
└── prod/      프로덕션 환경 (고가용성)
```

### 3. 원격 상태 관리 (Remote State)
- S3 Backend + DynamoDB Lock **설정이 준비되어 있습니다** (`environments/*/backend.tf`)
- 다만 학습 편의를 위해 **전부 주석 처리되어 있어 기본값은 로컬 State**입니다
- 주석을 해제하면 환경별 State 분리와 Lock을 실습할 수 있습니다

### 4. 프로덕션 체크리스트
- [x] 모듈 재사용 (`modules/`)
- [x] 환경별 변수 분리 (`environments/`)
- [ ] 원격 State 관리 (S3 + DynamoDB) — 설정만 준비, 주석 해제 필요
- [x] 태그 표준화 (common_tags)
- [x] 보안 그룹 최소 권한
- [x] 출력값 정리 (outputs)
- [x] 상세한 변수 검증 (validation)

## 사용법

### 환경별 배포

`environments/<환경>/`에는 **변수 파일과 backend 설정만** 들어 있습니다.
리소스를 정의하는 `main.tf`는 브랜치 루트에 하나뿐이므로,
그 디렉토리로 이동해서 `terraform apply`를 실행하면 아무 리소스도 만들어지지 않습니다.

항상 **브랜치 루트에서 실행하고 환경은 `-var-file`로 지정**합니다.

```bash
git checkout 10-production-ready
cd 10-production-ready

terraform init

# dev 환경
terraform plan  -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# staging 환경
terraform apply -var-file=environments/staging/terraform.tfvars

# prod 환경
terraform apply -var-file=environments/prod/terraform.tfvars
```

> ⚠️ 세 환경이 **하나의 State 파일을 공유**합니다.
> `environments/*/backend.tf`의 S3 backend 블록은 현재 전부 주석 처리되어 있어
> State가 로컬에 저장되기 때문입니다.
>
> 환경을 동시에 유지하려면 각 backend.tf의 주석을 해제하고
> 환경별로 `terraform init -reconfigure`를 실행해 State를 분리하세요.
> (S3 버킷과 DynamoDB 테이블을 먼저 만들어야 합니다 — 05-remote-state 참고)

## 아키텍처 다이어그램
```
┌─────────────────────────────────────────────┐
│                   AWS Cloud                  │
│  ┌─────────────────────────────────────────┐│
│  │              VPC (10.x.0.0/16)          ││
│  │  ┌──────────────┐  ┌──────────────┐     ││
│  │  │ Public Sub-1 │  │ Public Sub-2 │     ││
│  │  │  (AZ-a)      │  │  (AZ-c)      │     ││
│  │  │  ┌────────┐  │  │  ┌────────┐  │     ││
│  │  │  │  EC2   │  │  │  │  EC2   │  │     ││
│  │  │  └────────┘  │  │  └────────┘  │     ││
│  │  └──────────────┘  └──────────────┘     ││
│  │           │                │              ││
│  │      ┌────┴────────────────┴────┐        ││
│  │      │    Internet Gateway      │        ││
│  │      └──────────────────────────┘        ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

## 이 프로젝트에서 사용된 기술 (01~10 총정리)
| 브랜치 | 핵심 주제 |
|--------|-----------|
| 01-basic | Terraform 기초, VPC, EC2 |
| 02-basic-localstack | LocalStack 로컬 실습 환경 |
| 03-multi-environment | 환경별 관리, tfvars, locals |
| 04-modules-basic | 모듈 작성과 재사용 |
| 05-remote-state | S3 Backend, DynamoDB State Lock |
| 06-security-basic | IAM, KMS, Secrets Manager |
| 07-security-advanced | GuardDuty, Config, Security Hub |
| 08-monitoring | CloudWatch, CloudTrail, SNS |
| 09-ci-cd | GitHub Actions, 자동화 |
| **10-production-ready** | **모든 것의 종합** |

---

[← 메인 README](https://github.com/solzip/terraform-aws-study) | [← 이전: 09-ci-cd](https://github.com/solzip/terraform-aws-study/tree/09-ci-cd)

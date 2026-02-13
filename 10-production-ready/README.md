# 10. Production Ready - 프로덕션 수준 인프라

## 학습 목표
이 모듈은 **01~09에서 배운 모든 것을 종합**하여
실제 프로덕션에 사용할 수 있는 수준의 Terraform 코드를 작성합니다.

## 핵심 개념

### 1. 모듈화된 아키텍처
```
modules/
├── vpc/       VPC, Subnet, IGW, NAT, Route Table
├── ec2/       EC2 Instance, Auto Scaling 기반
└── security/  Security Group, IAM Role
```

### 2. 환경별 분리 (S3 Backend)
```
environments/
├── dev/       개발 환경 (최소 비용)
├── staging/   스테이징 환경 (Prod와 유사)
└── prod/      프로덕션 환경 (고가용성)
```

### 3. 원격 상태 관리 (Remote State)
- S3 Backend + DynamoDB Lock
- 환경별 State 파일 분리
- State Lock으로 동시 작업 충돌 방지

### 4. 프로덕션 체크리스트
- [x] 모듈 재사용 (`modules/`)
- [x] 환경별 변수 분리 (`environments/`)
- [x] 원격 State 관리 (S3 + DynamoDB)
- [x] 태그 표준화 (common_tags)
- [x] 보안 그룹 최소 권한
- [x] 출력값 정리 (outputs)
- [x] 상세한 변수 검증 (validation)

## 사용법

### 환경별 배포
```bash
# dev 환경
cd environments/dev
terraform init
terraform plan
terraform apply

# staging 환경
cd environments/staging
terraform init
terraform plan
terraform apply

# prod 환경
cd environments/prod
terraform init
terraform plan
terraform apply
```

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
| 02-variables | 변수 타입, validation, locals |
| 03-multi-environment | 환경별 관리, tfvars |
| 04-state-management | State 이해, 백엔드 |
| 05-module-basics | 모듈 작성과 재사용 |
| 06-security-basic | IAM, KMS, Secrets Manager |
| 07-security-advanced | GuardDuty, Config, Security Hub |
| 08-monitoring | CloudWatch, CloudTrail, SNS |
| 09-ci-cd | GitHub Actions, 자동화 |
| **10-production-ready** | **모든 것의 종합** |

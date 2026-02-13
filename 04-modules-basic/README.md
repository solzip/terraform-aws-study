# 04-modules-basic - 모듈화 기초

> 🟡 **난이도**: 중급 | **학습 시간**: 4시간

[← 메인 README로 돌아가기](../../) | [← 이전: 03-multi-environment](../../tree/03-multi-environment)

## 📚 학습 목표

- ✅ Terraform 모듈 설계 원칙 이해
- ✅ 재사용 가능한 모듈 생성 (VPC, EC2, Security Group)
- ✅ 모듈 입출력(Variables/Outputs) 설계
- ✅ 로컬 모듈 호출 및 조합
- ✅ 모듈 간 의존성 관리
- ✅ 모듈 버전 관리 개념

## 🏗️ 아키텍처

```
┌──────────────────────────────────────────────────┐
│  Root Module (main.tf)                           │
│                                                    │
│  ┌──────────────┐  ┌──────────────┐              │
│  │  VPC Module   │  │  SG Module   │              │
│  │  - VPC        │  │  - Web SG    │              │
│  │  - IGW        │  │  - SSH rules │              │
│  │  - Subnets    │  │  - HTTP rules│              │
│  │  - Route Table│  └──────┬───────┘              │
│  └──────┬───────┘          │                      │
│         │                  │                      │
│         └──────┬───────────┘                      │
│                │                                   │
│         ┌──────▼───────┐                           │
│         │  EC2 Module   │                          │
│         │  - Instance   │                          │
│         │  - User Data  │                          │
│         └──────────────┘                           │
└──────────────────────────────────────────────────┘
```

## 📁 프로젝트 구조

```
04-modules-basic/
├── README.md                 # 현재 문서
├── main.tf                   # 모듈 호출 (루트)
├── variables.tf              # 루트 변수
├── outputs.tf                # 루트 출력
├── versions.tf               # Terraform/Provider 버전
└── modules/                  # 재사용 가능한 모듈
    ├── vpc/
    │   ├── main.tf           # VPC, IGW, Subnet, Route Table
    │   ├── variables.tf      # VPC 모듈 입력 변수
    │   ├── outputs.tf        # VPC ID, Subnet ID 등 출력
    │   └── README.md         # VPC 모듈 사용법
    ├── ec2/
    │   ├── main.tf           # EC2 Instance
    │   ├── variables.tf      # EC2 모듈 입력 변수
    │   ├── outputs.tf        # Instance ID, IP 등 출력
    │   └── README.md         # EC2 모듈 사용법
    └── security-group/
        ├── main.tf           # Security Group + Rules
        ├── variables.tf      # SG 모듈 입력 변수
        ├── outputs.tf        # SG ID 출력
        └── README.md         # SG 모듈 사용법
```

## 🚀 실습 가이드

### 1단계: 브랜치 체크아웃
```bash
git checkout 04-modules-basic
```

### 2단계: 모듈 구조 확인
```bash
# 모듈 디렉토리 확인
ls -la modules/
ls -la modules/vpc/
ls -la modules/ec2/
ls -la modules/security-group/
```

### 3단계: 배포
```bash
terraform init      # 모듈 초기화 포함
terraform plan      # 모듈별 리소스 확인
terraform apply     # 배포
```

### 4단계: 리소스 정리
```bash
terraform destroy
```

## 💡 핵심 학습 포인트

### 1. 모듈 설계 원칙

```
모듈이란?
- 관련 리소스를 하나의 패키지로 묶은 것
- 입력(variables) → 처리(resources) → 출력(outputs) 구조
- 한 번 만들면 여러 곳에서 재사용 가능
```

**좋은 모듈의 조건**:
- 단일 책임: 하나의 기능만 담당 (VPC, EC2, SG 분리)
- 명확한 인터페이스: 입출력이 잘 정의됨
- 적절한 기본값: 바로 사용 가능하되 커스터마이징 가능
- 문서화: README.md로 사용법 설명

### 2. 모듈 호출 방법

```hcl
# 로컬 모듈 호출
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# 모듈 출력 참조
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_id
}
```

### 3. 모듈 간 데이터 전달

```hcl
# VPC 모듈의 출력을 EC2 모듈의 입력으로 전달
module "ec2" {
  source = "./modules/ec2"

  subnet_id          = module.vpc.public_subnet_id     # VPC 모듈 출력 참조
  security_group_ids = [module.sg.security_group_id]    # SG 모듈 출력 참조
}
```

### 4. 로컬 모듈 vs 원격 모듈

```hcl
# 로컬 모듈 (이 프로젝트)
module "vpc" {
  source = "./modules/vpc"
}

# 원격 모듈 (Terraform Registry)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
}

# Git 저장소 모듈
module "vpc" {
  source = "git::https://github.com/example/modules.git//vpc?ref=v1.0.0"
}
```

## 📊 모듈 입출력 요약

### VPC 모듈
| 입력 | 출력 |
|------|------|
| project_name | vpc_id |
| environment | vpc_cidr |
| vpc_cidr | public_subnet_id |
| public_subnet_cidr | public_subnet_cidr |
| | internet_gateway_id |

### Security Group 모듈
| 입력 | 출력 |
|------|------|
| project_name | security_group_id |
| environment | security_group_name |
| vpc_id | |
| allowed_ssh_cidrs | |
| allowed_http_cidrs | |

### EC2 모듈
| 입력 | 출력 |
|------|------|
| project_name | instance_id |
| environment | public_ip |
| instance_type | private_ip |
| subnet_id | public_dns |
| security_group_ids | |
| ami_id (optional) | |

## 🔧 베스트 프랙티스

### 1. 모듈 디렉토리 구조
```
modules/
└── 모듈명/
    ├── main.tf           # 리소스 정의 (필수)
    ├── variables.tf      # 입력 변수 (필수)
    ├── outputs.tf        # 출력 값 (필수)
    └── README.md         # 문서 (권장)
```

### 2. 변수에 항상 description 추가
```hcl
variable "vpc_cidr" {
  description = "VPC의 CIDR 블록"  # 이 설명이 terraform docs에 표시됨
  type        = string
  default     = "10.0.0.0/16"
}
```

### 3. 모듈 출력은 필요한 것만
```hcl
# 다른 모듈에서 참조할 값만 출력
output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}
```

## ✅ 학습 체크리스트

- [ ] 모듈의 개념과 필요성 이해
- [ ] VPC 모듈 구조 분석 (main.tf, variables.tf, outputs.tf)
- [ ] 모듈 간 데이터 전달 방식 이해
- [ ] `module` 블록으로 모듈 호출
- [ ] 모듈 출력값 참조 (`module.이름.출력`)
- [ ] 로컬 vs 원격 모듈 차이 이해
- [ ] 실제 배포 및 리소스 확인
- [ ] 리소스 정리 완료

## 🔄 다음 단계

모듈화 기초를 마스터했습니다! 🎉

```bash
terraform destroy
git checkout 05-remote-state
```

05-remote-state에서는:
- S3 Backend로 State 원격 관리
- DynamoDB State Locking
- 팀 협업을 위한 State 공유

[← 이전: 03-multi-environment](../../tree/03-multi-environment) | [다음: 05-remote-state →](../../tree/05-remote-state)

---

**작성일**: 2025-02-02
**난이도**: 🟡 중급
**학습 시간**: 4시간

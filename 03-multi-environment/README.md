# 03-multi-environment - 멀티 환경 관리

> 🟡 **난이도**: 중급 | **학습 시간**: 3시간

[← 메인 README로 돌아가기](../../) | [← 이전: 02-basic-localstack](../../tree/02-basic-localstack)

## 📚 학습 목표

- ✅ Dev, Staging, Prod 환경 분리 전략
- ✅ Terraform Workspace 활용
- ✅ 환경별 변수 파일 관리
- ✅ 디렉토리 기반 환경 구조
- ✅ 환경별 리소스 크기 조정

## 🏗️ 환경 구조

```
environments/
├── dev/
│   ├── terraform.tfvars        # Dev 환경 변수
│   ├── backend.tf              # Dev State 설정
│   └── README.md
├── staging/
│   ├── terraform.tfvars        # Staging 환경 변수
│   ├── backend.tf
│   └── README.md
└── prod/
    ├── terraform.tfvars        # Prod 환경 변수
    ├── backend.tf
    └── README.md
```

## 📁 프로젝트 구조

```
03-multi-environment/
├── README.md
├── environments/              # 환경별 설정
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/                   # 공통 모듈
│   └── web-app/
├── main.tf                    # 공통 리소스 정의
├── variables.tf
└── outputs.tf
```

## 🚀 실습 가이드

### 방법 1: 디렉토리 기반 (권장)

```bash
# Dev 환경 배포
cd environments/dev
terraform init
terraform apply

# Staging 환경 배포
cd ../staging
terraform init
terraform apply

# Prod 환경 배포
cd ../prod
terraform init
terraform apply
```

### 방법 2: Workspace 기반

```bash
# Workspace 생성
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Dev 환경으로 전환
terraform workspace select dev
terraform apply -var-file=environments/dev/terraform.tfvars

# Prod 환경으로 전환
terraform workspace select prod
terraform apply -var-file=environments/prod/terraform.tfvars
```

## 💡 환경별 설정 예시

### Dev 환경 (terraform.tfvars)
```hcl
environment    = "dev"
instance_type  = "t2.micro"     # 최소 사양
instance_count = 1               # 단일 인스턴스
enable_backup  = false           # 백업 비활성화
```

### Staging 환경
```hcl
environment    = "staging"
instance_type  = "t2.small"     # 중간 사양
instance_count = 2               # 이중화
enable_backup  = true            # 백업 활성화
```

### Prod 환경
```hcl
environment    = "prod"
instance_type  = "t3.medium"    # 고사양
instance_count = 3               # 멀티 AZ
enable_backup  = true
enable_monitoring = true
```

## 🔑 핵심 학습 포인트

### 1. 환경별 변수 관리

**variables.tf**:
```hcl
variable "environment" {
  description = "환경 이름"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "유효한 환경: dev, staging, prod"
  }
}

variable "instance_config" {
  description = "환경별 인스턴스 설정"
  type = map(object({
    instance_type  = string
    instance_count = number
  }))
  
  default = {
    dev = {
      instance_type  = "t2.micro"
      instance_count = 1
    }
    staging = {
      instance_type  = "t2.small"
      instance_count = 2
    }
    prod = {
      instance_type  = "t3.medium"
      instance_count = 3
    }
  }
}
```

**사용**:
```hcl
resource "aws_instance" "web" {
  count         = var.instance_config[var.environment].instance_count
  instance_type = var.instance_config[var.environment].instance_type
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-${count.index}"
    Environment = var.environment
  }
}
```

### 2. 조건부 리소스 생성

```hcl
# Prod 환경에서만 생성
resource "aws_db_instance" "main" {
  count = var.environment == "prod" ? 1 : 0
  
  instance_class = "db.t3.medium"
  # ...
}

# Dev에서는 단일 AZ, Prod에서는 Multi-AZ
resource "aws_rds_cluster" "main" {
  engine      = "aurora-mysql"
  multi_az    = var.environment == "prod" ? true : false
  # ...
}
```

### 3. 로컬 값 활용

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  # 환경별 설정
  is_production = var.environment == "prod"
  instance_count = local.is_production ? 3 : 1
  
  # CIDR 계산
  vpc_cidr = "10.${var.environment == "prod" ? 0 : var.environment == "staging" ? 1 : 2}.0.0/16"
}

resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr
  tags       = local.common_tags
}
```

## 📊 환경별 리소스 비교

| 리소스 | Dev | Staging | Prod |
|--------|-----|---------|------|
| EC2 타입 | t2.micro | t2.small | t3.medium |
| 인스턴스 수 | 1 | 2 | 3 |
| 가용 영역 | 1 | 2 | 3 |
| Auto Scaling | ❌ | ✅ | ✅ |
| Load Balancer | ❌ | ✅ | ✅ |
| RDS Multi-AZ | ❌ | ❌ | ✅ |
| 백업 | ❌ | Daily | Hourly |
| 모니터링 | Basic | Enhanced | Full |

## 🔧 베스트 프랙티스

### 1. 환경별 백엔드 분리
```hcl
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state-dev"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state-prod"
    key    = "prod/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
```

### 2. 환경별 변수 검증
```hcl
variable "allowed_cidr_blocks" {
  description = "접근 허용 IP"
  type        = list(string)
  
  # Dev: 모든 IP 허용
  # Prod: 특정 IP만 허용
  default = []
  
  validation {
    condition = (
      var.environment != "prod" ||
      length(var.allowed_cidr_blocks) > 0
    )
    error_message = "Prod 환경에서는 allowed_cidr_blocks 필수"
  }
}
```

### 3. 환경별 태그 전략
```hcl
locals {
  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      CostCenter  = var.environment == "prod" ? "Production" : "Development"
      Backup      = var.environment == "prod" ? "Required" : "Optional"
    }
  )
}
```

## 🐛 주의사항

### 1. State 파일 분리
- ⚠️ 환경마다 **별도의 State 파일** 사용
- ⚠️ Prod State는 **엄격한 접근 제어**
- ⚠️ State 백엔드 **잠금 기능** 활성화

### 2. 변수 보안
- ⚠️ 민감한 변수는 **Secrets Manager** 사용
- ⚠️ terraform.tfvars는 **.gitignore**에 추가
- ⚠️ Prod 비밀번호는 **절대 하드코딩 금지**

### 3. 배포 순서
```bash
# 권장 배포 순서
1. Dev 환경 배포 및 테스트
2. Staging 환경 배포 및 검증
3. Prod 환경 배포 (승인 필요)
```

## ✅ 학습 체크리스트

- [ ] 환경별 디렉토리 구조 이해
- [ ] Workspace 사용법 숙지
- [ ] 환경별 변수 파일 작성
- [ ] 조건부 리소스 생성
- [ ] 환경별 State 파일 분리
- [ ] Dev → Staging → Prod 순서로 배포 경험
- [ ] 환경별 비용 차이 이해

## 🔄 다음 단계

멀티 환경 관리를 마스터했습니다! 🎉

```bash
# 다음 브랜치로 이동
git checkout 04-modules-basic
```

04-modules-basic에서는:
- 재사용 가능한 모듈 설계
- 모듈 입출력 정의
- 모듈 버전 관리

[← 이전: 02-basic-localstack](../../tree/02-basic-localstack) | [다음: 04-modules-basic →](../../tree/04-modules-basic)

---

**작성일**: 2025-02-02  
**난이도**: 🟡 중급  
**학습 시간**: 3시간
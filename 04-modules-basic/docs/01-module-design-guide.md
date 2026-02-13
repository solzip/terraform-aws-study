# 모듈 설계 가이드

## 모듈이란?

Terraform 모듈은 관련 리소스를 하나의 패키지로 묶어 **재사용 가능한 단위**로 만든 것입니다.

```
입력(variables) → 처리(resources) → 출력(outputs)
```

## 모듈 설계 원칙

### 1. 단일 책임 원칙 (Single Responsibility)

하나의 모듈은 하나의 기능만 담당합니다.

```
# 좋은 예 - 기능별 분리
modules/
├── vpc/              # 네트워크만 담당
├── ec2/              # 컴퓨팅만 담당
└── security-group/   # 방화벽만 담당

# 나쁜 예 - 모든 것을 하나에
modules/
└── everything/       # VPC + EC2 + SG 전부
```

### 2. 명확한 인터페이스

모듈의 입력(variables)과 출력(outputs)이 잘 정의되어야 합니다.

```hcl
# variables.tf - 모듈이 필요로 하는 값
variable "vpc_id" {
  description = "Security Group을 생성할 VPC ID"  # 설명 필수
  type        = string                               # 타입 명시
}

# outputs.tf - 모듈이 내보내는 값
output "security_group_id" {
  description = "생성된 Security Group ID"
  value       = aws_security_group.web.id
}
```

### 3. 적절한 기본값

바로 사용 가능하되, 필요시 커스터마이징할 수 있어야 합니다.

```hcl
variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"   # 기본값 제공 → 바로 사용 가능
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  # default 없음 → 반드시 전달해야 함 (필수 입력)
}
```

## 모듈 간 데이터 전달

이 프로젝트의 핵심 패턴입니다.

```
┌──────────┐     vpc_id      ┌──────────────────┐
│ VPC 모듈  │ ──────────────→ │ Security Group 모듈│
└─────┬────┘                  └────────┬─────────┘
      │                                │
      │ subnet_id              sg_id   │
      │                                │
      └──────────┐  ┌─────────────────┘
                  ▼  ▼
              ┌──────────┐
              │ EC2 모듈  │
              └──────────┘
```

```hcl
# main.tf (루트 모듈)

# 1단계: VPC 생성
module "vpc" {
  source = "./modules/vpc"
  # ...
}

# 2단계: VPC ID를 받아서 SG 생성
module "security_group" {
  vpc_id = module.vpc.vpc_id        # ← VPC 모듈의 출력 참조
}

# 3단계: Subnet ID와 SG ID를 받아서 EC2 생성
module "ec2" {
  subnet_id          = module.vpc.public_subnet_id
  security_group_ids = [module.security_group.security_group_id]
}
```

## 로컬 모듈 vs 원격 모듈

### 로컬 모듈 (이 프로젝트)

```hcl
module "vpc" {
  source = "./modules/vpc"    # 상대 경로
}
```

- 같은 저장소 내에 있는 모듈
- 빠른 개발 및 테스트에 적합
- 버전 관리는 Git 브랜치/태그로

### Terraform Registry 모듈

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"           # 버전 고정 필수
}
```

- 커뮤니티에서 유지보수하는 검증된 모듈
- 프로덕션에서 많이 사용
- [registry.terraform.io](https://registry.terraform.io) 에서 검색

### Git 저장소 모듈

```hcl
module "vpc" {
  source = "git::https://github.com/org/modules.git//vpc?ref=v1.0.0"
}
```

- 조직 내부 모듈 공유에 적합
- `ref`로 특정 버전(태그/브랜치) 지정

## 모듈 버전 관리 전략

```
v1.0.0  ← 초기 릴리즈
v1.1.0  ← 새 기능 추가 (하위 호환)
v1.1.1  ← 버그 수정
v2.0.0  ← 인터페이스 변경 (하위 호환 깨짐)
```

- **Major**: 입력/출력 변경 등 하위 호환이 깨지는 변경
- **Minor**: 새 변수 추가 (기본값 있음) 등 하위 호환 유지
- **Patch**: 내부 구현 버그 수정

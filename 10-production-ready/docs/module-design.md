# 모듈 설계 가이드

## 모듈이란?

### 한 줄 정의
```
Terraform 모듈 = 재사용 가능한 Terraform 코드 묶음
```

### 왜 모듈을 사용하는가?
```
모듈 없이 (단일 파일):
├── main.tf에 모든 리소스 정의 (수백 줄)
├── 환경별로 파일 복사 (코드 중복)
├── 수정할 때 여러 파일을 동시에 변경
└── ❌ 유지보수 어려움

모듈 사용 (분리된 파일):
├── modules/vpc/   → 네트워크만 관리
├── modules/ec2/   → 컴퓨팅만 관리
├── modules/security/ → 보안만 관리
├── 환경별로 변수만 다르게 전달
└── ✅ 유지보수 쉬움, 재사용 가능
```

## 이 프로젝트의 모듈 구조

### 전체 구조
```
10-production-ready/
├── main.tf                 ← 모듈 호출 (오케스트레이터)
├── variables.tf            ← 전역 변수
├── outputs.tf              ← 전역 출력
│
├── modules/
│   ├── vpc/                ← 네트워크 모듈
│   │   ├── main.tf         리소스 정의
│   │   ├── variables.tf    입력 변수
│   │   └── outputs.tf      출력 값
│   │
│   ├── ec2/                ← 컴퓨팅 모듈
│   │   ├── main.tf         리소스 정의
│   │   ├── variables.tf    입력 변수
│   │   ├── outputs.tf      출력 값
│   │   └── user_data.sh.tpl  EC2 초기화 템플릿
│   │
│   └── security/           ← 보안 모듈
│       ├── main.tf         리소스 정의
│       ├── variables.tf    입력 변수
│       └── outputs.tf      출력 값
│
└── environments/           ← 환경별 설정
    ├── dev/
    ├── staging/
    └── prod/
```

### 모듈 간 데이터 흐름
```
                    variables.tf (전역 변수)
                         │
                         ▼
              ┌─── main.tf (오케스트레이터) ───┐
              │          │                      │
              ▼          ▼                      ▼
         module.vpc  module.security       module.ec2
              │          │                      ▲
              │          │                      │
              └──────────┴──────────────────────┘
                  출력값으로 연결 (느슨한 결합)

예: module.vpc.vpc_id → module.security의 vpc_id 변수
    module.vpc.public_subnet_ids → module.ec2의 subnet_ids 변수
    module.security.web_sg_id → module.ec2의 security_group_id 변수
```

## 모듈 설계 원칙

### 원칙 1: 단일 책임 (Single Responsibility)
```
좋은 예:
├── modules/vpc/      → 네트워크만
├── modules/ec2/      → 컴퓨팅만
└── modules/security/ → 보안만

나쁜 예:
└── modules/infrastructure/ → 모든 것을 다 포함
    (VPC + EC2 + SG + IAM + ...)
```

### 원칙 2: 명시적 인터페이스
```
모듈의 인터페이스 = variables.tf + outputs.tf

variables.tf:
├── 모듈이 필요한 입력값을 명시
├── description으로 용도 설명
└── validation으로 잘못된 값 방지

outputs.tf:
├── 다른 모듈에 제공할 값을 명시
├── 필요한 것만 노출 (최소 노출)
└── description으로 용도 설명
```

### 원칙 3: 느슨한 결합
```
좋은 예 (출력값으로 연결):
  module.vpc.vpc_id → module.security의 변수로 전달
  → VPC 모듈을 교체해도 인터페이스만 맞으면 OK

나쁜 예 (직접 참조):
  module.security 내부에서 aws_vpc.main.id 직접 참조
  → VPC 리소스 이름이 바뀌면 보안 모듈도 수정 필요
```

### 원칙 4: 합리적 기본값
```
# 좋은 예: 기본값이 있어서 간단히 사용 가능
variable "instance_type" {
  default = "t2.micro"  # Free Tier
}

# 나쁜 예: 기본값 없이 항상 입력 필요
variable "instance_type" {
  # default 없음 → 매번 값을 지정해야 함
}
```

## 환경별 사용 방법

### 방법 1: tfvars 파일 (이 프로젝트에서 사용)
```bash
# dev 환경
terraform plan -var-file=environments/dev/terraform.tfvars

# prod 환경
terraform plan -var-file=environments/prod/terraform.tfvars
```

### 방법 2: Workspace (소규모 프로젝트)
```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
terraform plan
```

### 방법 3: 환경별 디렉토리 (대규모 프로젝트)
```
environments/
├── dev/
│   ├── backend.tf      # dev State 설정
│   ├── terraform.tfvars # dev 변수
│   └── main.tf         # 루트 모듈 호출
├── staging/
│   ├── backend.tf
│   ├── terraform.tfvars
│   └── main.tf
└── prod/
    ├── backend.tf
    ├── terraform.tfvars
    └── main.tf
```

# 01-basic - Terraform 기초

> 🟢 **난이도**: 초급 | **학습 시간**: 2-3시간

[← 메인 README](https://github.com/solzip/terraform-aws-study) | [다음: 02-basic-localstack →](https://github.com/solzip/terraform-aws-study/tree/02-basic-localstack)

## 📚 이 브랜치에서 배우는 것

이 브랜치는 Terraform의 가장 기본적인 개념과 AWS 인프라 구축 방법을 학습합니다.

### 학습 목표
- ✅ Terraform 기본 문법 (HCL) 이해
- ✅ Provider 설정 방법
- ✅ 기본 리소스 생성 (VPC, EC2, Security Group)
- ✅ Variables와 Outputs 활용
- ✅ State 파일의 역할 이해
- ✅ Terraform 워크플로우 (init → plan → apply → destroy)

## 🏗️ 생성되는 AWS 리소스

```
┌─────────────────────────────────────────────────────────┐
│                VPC (10.0.0.0/16)                        │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │     Public Subnet (10.0.1.0/24)                   │ │
│  │     Availability Zone: ap-northeast-2a            │ │
│  │                                                   │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  EC2 Instance                               │ │ │
│  │  │  - Type: t2.micro                           │ │ │
│  │  │  - OS: Amazon Linux 2023                    │ │ │
│  │  │  - Apache Web Server (자동 설치)            │ │ │
│  │  │  - Public IP: Auto-assigned                 │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  │                                                   │ │
│  │  Security Group                                   │ │
│  │  - Inbound: Port 80 (HTTP) from 0.0.0.0/0        │ │
│  │  - Inbound: Port 22 (SSH) from 0.0.0.0/0         │ │
│  │  - Outbound: All traffic                         │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Internet Gateway                                       │
│  - Enables internet access                             │
│                                                         │
│  Route Table                                            │
│  - Routes: 0.0.0.0/0 → Internet Gateway                │
└─────────────────────────────────────────────────────────┘
```

### 리소스 상세
1. **VPC** (aws_vpc.main)
    - CIDR: 10.0.0.0/16 (65,536 IP 주소)
    - DNS 호스트네임 활성화
    - DNS 지원 활성화

2. **Internet Gateway** (aws_internet_gateway.main)
    - VPC의 인터넷 연결 제공

3. **Public Subnet** (aws_subnet.public)
    - CIDR: 10.0.1.0/24 (256 IP 주소)
    - 가용영역: ap-northeast-2a
    - Public IP 자동 할당

4. **Route Table** (aws_route_table.public)
    - 인터넷 트래픽을 IGW로 라우팅

5. **Security Group** (aws_security_group.web)
    - HTTP(80), SSH(22) 포트 오픈

6. **EC2 Instance** (aws_instance.web)
    - t2.micro (프리티어)
    - Apache 웹 서버 자동 설치

## 📁 프로젝트 구조

```
01-basic/
├── README.md                      # 현재 문서
├── docs/                          # 상세 문서
│   ├── 01-setup.md               # 초기 설정 가이드
│   ├── 02-execution.md           # 실행 가이드
│   └── 03-cleanup.md             # 정리 가이드
├── main.tf                        # 주요 리소스 정의
├── variables.tf                   # 입력 변수 선언
├── outputs.tf                     # 출력 값 정의
├── versions.tf                    # Terraform/Provider 버전
└── terraform.tfvars.example       # 변수 값 예시
```

> `.gitignore`는 이 디렉토리가 아니라 저장소 루트에 하나만 있으며 전체에 적용됩니다.

## 🚀 실습 시작하기

### 사전 준비
- Terraform 1.0 이상 설치
- AWS CLI 설정 완료
- AWS 계정 및 IAM 자격증명

### Step 1: 브랜치 체크아웃
```bash
git checkout 01-basic

# 실습 코드는 브랜치와 같은 이름의 디렉토리 안에 있습니다
cd 01-basic
```

### Step 2: 변수 파일 설정
```bash
# 예시 파일 복사
cp terraform.tfvars.example terraform.tfvars

# 에디터로 열어서 값 수정
vim terraform.tfvars
# 또는
code terraform.tfvars
```

**terraform.tfvars 설정 예시**:
```hcl
# AWS 리전 설정
aws_region = "ap-northeast-2"  # 서울 리전

# 환경 구분
environment = "dev"

# 프로젝트 이름 (리소스 태그에 사용)
project_name = "my-terraform-basic"

# 네트워크 설정
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# EC2 설정
instance_type = "t2.micro"  # 프리티어
```

### Step 3: Terraform 초기화
```bash
terraform init
```

**출력 예시**:
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.31.0...
- Installed hashicorp/aws v5.31.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan".
```

**이 단계에서 생성되는 것**:
- `.terraform/` 디렉토리 (Provider 플러그인)
- `.terraform.lock.hcl` 파일 (Provider 버전 잠금)

### Step 4: 실행 계획 확인
```bash
terraform plan
```

**출력 예시**:
```
Terraform will perform the following actions:

  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami                          = "ami-0c9c942bd7bf113a2"
      + instance_type                = "t2.micro"
      + subnet_id                    = (known after apply)
      ...
    }

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block                   = "10.0.0.0/16"
      + enable_dns_hostnames         = true
      ...
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + instance_id        = (known after apply)
  + instance_public_ip = (known after apply)
  + vpc_id             = (known after apply)
  + web_url            = (known after apply)
```

**확인 사항**:
- ✅ 7개의 리소스가 생성될 예정
- ✅ VPC, Subnet, EC2 등 필요한 리소스 포함
- ✅ 의도하지 않은 리소스가 없는지 확인

### Step 5: 인프라 배포
```bash
terraform apply
```

확인 메시지가 나타나면 `yes` 입력:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

**배포 진행 중**:
```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 3s [id=vpc-0123456789abcdef0]
aws_internet_gateway.main: Creating...
aws_subnet.public: Creating...
...
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Still creating... [20s elapsed]
aws_instance.web: Creation complete after 32s [id=i-0123456789abcdef0]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-0123456789abcdef0"
instance_public_ip = "13.125.123.45"
security_group_id = "sg-0123456789abcdef0"
vpc_id = "vpc-0123456789abcdef0"
web_url = "http://13.125.123.45"
```

### Step 6: 배포 확인

#### 6.1 웹 브라우저로 접속
```bash
# 출력된 URL로 브라우저 접속
# http://13.125.123.45
```

**예상 화면**:
```html
Hello from Terraform!
Instance ID: i-0123456789abcdef0
Availability Zone: ap-northeast-2a
```

#### 6.2 curl로 확인
```bash
curl $(terraform output -raw web_url)
```

#### 6.3 AWS Console에서 확인
1. AWS Console 로그인
2. EC2 서비스로 이동
3. 인스턴스 목록에서 `my-terraform-basic-dev-web-server` 확인
4. VPC 대시보드에서 생성된 VPC 확인

#### 6.4 Terraform으로 리소스 확인
```bash
# 모든 리소스 목록
terraform state list

# 출력:
# aws_instance.web
# aws_internet_gateway.main
# aws_route_table.public
# aws_route_table_association.public
# aws_security_group.web
# aws_subnet.public
# aws_vpc.main

# 특정 리소스 상세 정보
terraform state show aws_instance.web
```

### Step 7: 리소스 정리
```bash
# 모든 리소스 삭제
terraform destroy
```

확인 메시지에 `yes` 입력:
```
Do you really want to destroy all resources?
  Enter a value: yes
```

**삭제 진행**:
```
aws_route_table_association.public: Destroying...
aws_instance.web: Destroying...
aws_instance.web: Still destroying... [10s elapsed]
aws_instance.web: Destruction complete after 32s
aws_route_table.public: Destroying...
...
Destroy complete! Resources: 7 destroyed.
```

## 💡 핵심 학습 포인트

### 1. Terraform 파일 구조 이해

#### versions.tf - Provider 버전 관리
```hcl
terraform {
  # Terraform CLI의 최소 버전
  required_version = ">= 1.0"
  
  # 사용할 Provider 정의
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # 공식 레지스트리
      version = "~> 5.0"          # 5.x 버전 사용
    }
  }
}

# AWS Provider 설정
provider "aws" {
  region = var.aws_region  # 변수로 리전 지정
  
  # 모든 리소스에 자동 태그 추가
  default_tags {
    tags = {
      Project     = "terraform-basic"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
```

**학습 포인트**:
- 버전 고정으로 팀원 간 동일한 환경 보장
- `~> 5.0`: 5.0 이상, 6.0 미만 (마이너 버전 업데이트 허용)
- `default_tags`: 모든 리소스에 자동으로 태그 추가

---

#### variables.tf - 변수 선언
```hcl
# 기본 변수 선언
variable "aws_region" {
  description = "AWS 리소스를 생성할 리전"
  type        = string
  default     = "ap-northeast-2"
}

# 검증이 있는 변수
variable "environment" {
  description = "환경 구분 (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  # 입력값 검증
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 dev, staging, prod 중 하나여야 합니다."
  }
}

# CIDR 블록 변수
variable "vpc_cidr" {
  description = "VPC의 CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "올바른 CIDR 형식이어야 합니다."
  }
}
```

**학습 포인트**:
- `description`: 변수의 목적 명확히
- `type`: string, number, bool, list, map 등
- `default`: 기본값 (없으면 필수 입력)
- `validation`: 입력값 검증으로 오류 방지

**변수 사용 방법**:
```hcl
# 1. 코드에서 참조
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr  # var.변수명
}

# 2. 문자열 보간
tags = {
  Name = "${var.project_name}-${var.environment}-vpc"
}

# 3. 조건부 사용
instance_type = var.environment == "prod" ? "t3.medium" : "t2.micro"
```

---

#### main.tf - 리소스 정의
```hcl
# VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # 위에서 생성한 VPC 참조

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# EC2 인스턴스 생성
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id  # Data source 참조
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  
  # 여러 리소스 참조
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # User Data - 인스턴스 시작 시 실행되는 스크립트
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-web-server"
  }
}
```

**학습 포인트**:
- 리소스 간 의존성: Terraform이 자동으로 순서 결정
- 암시적 의존성: `aws_vpc.main.id` 참조
- 명시적 의존성: `depends_on = [aws_internet_gateway.main]`
- Heredoc 문법: `<<-EOF ... EOF` (여러 줄 문자열)

---

#### outputs.tf - 출력값 정의
```hcl
output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = aws_vpc.main.id
}

output "instance_public_ip" {
  description = "EC2 인스턴스의 Public IP 주소"
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "웹 서버 접속 URL"
  value       = "http://${aws_instance.web.public_ip}"
}

# 민감한 정보는 sensitive 표시
output "instance_id" {
  description = "EC2 인스턴스의 ID"
  value       = aws_instance.web.id
  sensitive   = false  # true로 설정하면 출력 시 가려짐
}
```

**학습 포인트**:
- 중요한 정보를 사용자에게 표시
- 다른 모듈에서 참조 가능
- `terraform output` 명령으로 확인
- 자동화 스크립트에서 활용 가능

**사용 예시**:
```bash
# 모든 출력값 확인
terraform output

# 특정 출력값만 확인
terraform output web_url

# Raw 형식으로 출력 (스크립트에서 사용)
WEB_URL=$(terraform output -raw web_url)
curl $WEB_URL

# JSON 형식으로 출력
terraform output -json
```

---

### 2. Terraform 워크플로우

```
┌──────────────┐
│  terraform   │
│    init      │  ← Provider 다운로드 및 초기화
└──────┬───────┘
       │
       v
┌──────────────┐
│  terraform   │
│    plan      │  ← 변경 사항 미리보기 (실행 안 함)
└──────┬───────┘
       │
       v
┌──────────────┐
│  terraform   │
│    apply     │  ← 실제 리소스 생성/변경
└──────┬───────┘
       │
       v
┌──────────────┐
│   인프라     │
│    사용      │  ← 생성된 리소스 활용
└──────┬───────┘
       │
       v
┌──────────────┐
│  terraform   │
│   destroy    │  ← 리소스 삭제
└──────────────┘
```

**각 단계별 설명**:

1. **init**: 작업 디렉토리 초기화
    - Provider 플러그인 다운로드
    - Backend 초기화
    - 모듈 다운로드 (있는 경우)
    - `.terraform/` 디렉토리 생성

2. **plan**: 실행 계획 수립
    - 현재 State와 코드 비교
    - 생성/변경/삭제될 리소스 확인
    - **실제로 리소스 변경하지 않음**

3. **apply**: 계획 실행
    - Plan 단계 자동 실행
    - 사용자 확인 요청
    - 실제 리소스 생성/변경
    - State 파일 업데이트

4. **destroy**: 리소스 삭제
    - 관리 중인 모든 리소스 삭제
    - 역순으로 삭제 (의존성 고려)
    - State 파일에서 제거

---

### 3. State 파일의 역할

**terraform.tfstate 파일**:
```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "resources": [
    {
      "type": "aws_vpc",
      "name": "main",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "attributes": {
            "id": "vpc-0123456789abcdef0",
            "cidr_block": "10.0.0.0/16",
            ...
          }
        }
      ]
    }
  ]
}
```

**State 파일이 하는 일**:
1. **현재 상태 추적**: AWS에 실제로 생성된 리소스 정보 저장
2. **변경 사항 감지**: 코드와 실제 인프라 비교
3. **메타데이터 저장**: 리소스 ID, 속성값 등
4. **성능 향상**: AWS API 호출 최소화

**⚠️ 중요 주의사항**:
- State 파일에는 **민감한 정보**가 포함될 수 있음
- Git에 **절대 커밋하지 말 것**
- 팀 작업 시 **원격 State** 사용 (05-remote-state 브랜치에서 학습)
- 백업 필수

**State 관리 명령어**:
```bash
# State 파일 리소스 목록
terraform state list

# 특정 리소스 상세 정보
terraform state show aws_instance.web

# State 새로고침 (AWS 실제 상태 반영)
terraform refresh

# State에서 리소스 제거
terraform state rm aws_instance.web
```

---

### 4. 리소스 간 의존성

Terraform은 리소스 간 의존성을 자동으로 파악합니다.

**암시적 의존성** (자동 감지):
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id  # VPC를 참조 → 의존성 자동 생성
  ...
}
```

실행 순서:
1. aws_vpc.main 생성
2. aws_subnet.public 생성 (VPC ID 필요)

**명시적 의존성** (수동 지정):
```hcl
resource "aws_instance" "web" {
  ...
  
  # IGW가 생성된 후에 인스턴스 생성
  depends_on = [aws_internet_gateway.main]
}
```

**의존성 그래프 확인**:
```bash
terraform graph | dot -Tpng > graph.png
```

## 📖 상세 가이드 문서

더 자세한 내용은 다음 문서를 참고하세요:

1. **[초기 설정 가이드](docs/01-setup.md)**
    - Terraform 설치 방법 (macOS, Windows, Linux)
    - AWS CLI 설정
    - IAM 사용자 생성
    - 프로젝트 초기화

2. **[실행 가이드](docs/02-execution.md)**
    - 모든 명령어 상세 설명
    - 트러블슈팅 가이드
    - 유용한 팁과 트릭
    - 검증 및 테스트 방법

3. **[정리 가이드](docs/03-cleanup.md)**
    - 안전한 리소스 삭제 방법
    - 비용 발생 방지
    - 로컬 파일 정리
    - State 파일 관리

## 🐛 자주 발생하는 문제

### 문제 1: AWS 자격증명 오류
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**원인**: AWS 자격증명이 설정되지 않음

**해결방법**:
```bash
# AWS CLI 재설정
aws configure

# 입력 사항:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: ap-northeast-2
# - Default output format: json

# 설정 확인
aws sts get-caller-identity
```

---

### 문제 2: 리소스 이름 중복
```
Error: creating EC2 Instance: InvalidParameterValue: ...
```

**원인**: 이전에 생성한 리소스가 남아있음

**해결방법**:
```bash
# 1. State 파일 확인
ls -la terraform.tfstate*

# 2. 기존 리소스 정리
terraform destroy

# 3. State 파일 삭제 (주의!)
rm terraform.tfstate*

# 4. 다시 시도
terraform apply
```

---

### 문제 3: Port 80 접속 안됨
**증상**: 웹 브라우저에서 접속이 안 됨

**해결방법**:
```bash
# 1. Security Group 규칙 확인
terraform state show aws_security_group.web

# 2. 인스턴스 상태 확인
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].State.Name'

# 3. 인스턴스 부팅 대기 (초기 5-10분 소요)
# User Data 스크립트 실행 로그 확인
aws ec2 get-console-output \
  --instance-id $(terraform output -raw instance_id)

# 4. 직접 접속 테스트
curl -v http://$(terraform output -raw instance_public_ip)
```

---

### 문제 4: terraform.tfvars가 없어요
```
Error: No value for required variable
```

**원인**: 변수 파일이 생성되지 않음

**해결방법**:
```bash
# 예시 파일 복사
cp terraform.tfvars.example terraform.tfvars

# 에디터로 열어서 값 수정
vim terraform.tfvars
```

---

### 문제 5: Provider 다운로드 실패
```
Error: Failed to install provider
```

**해결방법**:
```bash
# 1. .terraform 디렉토리 삭제
rm -rf .terraform .terraform.lock.hcl

# 2. 다시 초기화
terraform init

# 3. 프록시 사용 중이라면
export HTTPS_PROXY=http://proxy.example.com:8080
terraform init
```

더 많은 트러블슈팅은 [실행 가이드](docs/02-execution.md#트러블슈팅)를 참고하세요.

## 💰 비용 안내

이 브랜치에서 생성하는 모든 리소스는 **AWS 프리티어 무료 범위** 내에서 사용 가능합니다!

### 프리티어 혜택
- ✅ **EC2 t2.micro**: 750시간/월 무료 (1대 24시간 운영 가능)
- ✅ **VPC, Subnet, IGW**: 무료
- ✅ **Security Group**: 무료
- ✅ **Data Transfer**: 15GB/월 무료
- ✅ **Elastic IP**: 인스턴스에 연결된 상태면 무료

### 비용 발생 가능성
- ⚠️ Elastic IP를 할당만 하고 사용하지 않으면 시간당 $0.005
- ⚠️ 프리티어 초과 시 (750시간 초과, 15GB 데이터 전송 초과)
- ⚠️ 실습 후 리소스를 삭제하지 않으면 계속 비용 발생

### 💡 비용 절약 팁
```bash
# 1. 실습 중이 아닐 때는 리소스 삭제
terraform destroy

# 2. 인스턴스만 중지 (데이터는 유지)
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)

# 3. AWS Budgets 설정 (무료)
# - 월 $5 예산 설정
# - 80% 도달 시 이메일 알림
```

**⚠️ 중요**: 실습 후 반드시 `terraform destroy`로 리소스를 삭제하세요!

## 📝 학습 노트 작성

학습한 내용을 정리해보세요:

```bash
# 개인 학습 노트 작성
mkdir -p learning-notes

cat > learning-notes/01-basic-notes.md << 'EOF'
# 01-basic 학습 정리

## 📅 학습일: 2025-02-02

## ✅ 배운 내용
- Terraform 기본 명령어 (init, plan, apply, destroy)
- HCL 문법의 기본 구조
- AWS VPC와 EC2의 관계
- Security Group의 역할
- State 파일의 중요성

## 🤔 어려웠던 점
- Security Group 규칙 설정 시 CIDR 이해
- State 파일의 정확한 역할 파악
- 리소스 간 의존성 자동 감지 원리

## 💡 핵심 개념
1. **Infrastructure as Code**: 인프라를 코드로 관리
2. **선언적 구문**: "무엇을" 만들지 정의 (어떻게는 Terraform이 처리)
3. **Idempotency**: 같은 코드를 여러 번 실행해도 결과 동일

## 🔄 다시 복습 필요
- [ ] Data Source vs Resource 차이
- [ ] 암시적 vs 명시적 의존성
- [ ] State 파일 백업 전략

## 🎯 다음에 공부할 것
- LocalStack으로 로컬 개발 환경 구축
- Terraform 모듈 구조
- Remote State 관리

## 📌 유용한 명령어 메모
```bash
# 특정 리소스만 다시 생성
terraform apply -target=aws_instance.web

# State 파일 백업
cp terraform.tfstate terraform.tfstate.backup

# 리소스 정보 빠르게 확인
terraform show -json | jq '.values.root_module.resources'
```

## 🔗 참고한 자료
- Terraform 공식 문서
- AWS VPC 문서
- 실습 중 발생한 에러 해결 방법
  EOF
```

## ✅ 학습 체크리스트

이 브랜치를 완료했다면 다음 항목을 확인하세요:

### 기본 이해
- [ ] Terraform의 목적과 장점 이해
- [ ] IaC(Infrastructure as Code) 개념 이해
- [ ] HCL 기본 문법 이해

### 명령어 숙달
- [ ] `terraform init` 실행 및 이해
- [ ] `terraform plan` 출력 해석 가능
- [ ] `terraform apply` 성공적 실행
- [ ] `terraform destroy` 안전하게 사용

### 파일 구조
- [ ] `versions.tf`의 역할 이해
- [ ] `variables.tf`에서 변수 선언
- [ ] `main.tf`에서 리소스 정의
- [ ] `outputs.tf`에서 출력값 활용

### AWS 리소스
- [ ] VPC 생성 및 이해
- [ ] Subnet과 가용영역 개념 이해
- [ ] Security Group 규칙 작성
- [ ] EC2 인스턴스 생성 및 접속

### State 관리
- [ ] State 파일의 역할 이해
- [ ] `terraform state` 명령어 사용
- [ ] State 파일을 Git에 커밋하지 않는 이유 이해

### 실전 경험
- [ ] 실제 EC2 인스턴스 생성 및 웹 서버 확인
- [ ] 웹 브라우저로 접속 성공
- [ ] 리소스 정리 완료 (`terraform destroy`)
- [ ] 최소 1번 이상 에러 경험하고 해결

### 추가 학습
- [ ] AWS Console에서 생성된 리소스 확인
- [ ] `terraform graph` 명령어로 의존성 시각화
- [ ] 개인 학습 노트 작성

## 🔄 다음 단계

축하합니다! Terraform 기초를 완료했습니다! 🎉

### 복습 포인트
- Terraform 워크플로우: init → plan → apply → destroy
- 리소스 참조: `aws_vpc.main.id`
- 변수 사용: `var.vpc_cidr`
- 출력값 활용: `terraform output`

### 다음 브랜치 준비
```bash
# 현재 리소스 정리
terraform destroy

# 변경사항 커밋 (학습 노트 등)
git add learning-notes/
git commit -m "docs: Add learning notes for 01-basic"

# 다음 브랜치로 이동
git checkout 02-basic-localstack
```

### 다음 학습 주제: LocalStack
02-basic-localstack 브랜치에서는:
- 💰 AWS 비용 걱정 없이 로컬에서 실습
- 🐳 Docker로 AWS 서비스 시뮬레이션
- ⚡ 빠른 테스트 및 개발 환경 구축

[← 메인 README로 돌아가기](https://github.com/solzip/terraform-aws-study) | [다음: 02-basic-localstack →](https://github.com/solzip/terraform-aws-study/tree/02-basic-localstack)

---

**작성일**: 2025-02-02  
**난이도**: 🟢 초급  
**예상 소요 시간**: 2-3시간  
**프리티어**: ✅ 무료 범위 내
<!--
==========================================================
  브랜치 README 작성 템플릿
==========================================================
  이 파일은 그대로 읽는 문서가 아니라 **복사해서 쓰는 템플릿**입니다.
  아래 내용을 `<브랜치명>/README.md`로 복사한 뒤 값을 교체하세요.

  - 제목/난이도/학습 시간을 해당 브랜치에 맞게 수정
  - `docs/...` 상대 링크는 브랜치 디렉토리 기준이므로 복사 후 정상 동작합니다
  - 이전/다음 브랜치 링크는 절대 URL을 사용합니다 (상대 경로는 GitHub에서 깨집니다)
==========================================================
-->

# 01-basic - Terraform 기초

> 🟢 **난이도**: 초급 | **학습 시간**: 2-3시간

[← 메인 README로 돌아가기](https://github.com/solzip/terraform-aws-study)

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
┌─────────────────────────────────────────┐
│           VPC (10.0.0.0/16)            │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Public Subnet (10.0.1.0/24)     │ │
│  │                                   │ │
│  │  ┌─────────────────────────────┐ │ │
│  │  │  EC2 Instance (t2.micro)    │ │ │
│  │  │  - Amazon Linux 2023        │ │ │
│  │  │  - Apache Web Server        │ │ │
│  │  └─────────────────────────────┘ │ │
│  │                                   │ │
│  │  Security Group                   │ │
│  │  - Port 80 (HTTP)                 │ │
│  │  - Port 22 (SSH)                  │ │
│  └───────────────────────────────────┘ │
│                                         │
│  Internet Gateway                       │
└─────────────────────────────────────────┘
```

### 리소스 목록
1. **VPC** - 격리된 네트워크 공간
2. **Internet Gateway** - 인터넷 연결
3. **Public Subnet** - 퍼블릭 접근 가능한 서브넷
4. **Route Table** - 네트워크 라우팅
5. **Security Group** - 방화벽 규칙
6. **EC2 Instance** - 가상 서버

## 📁 프로젝트 구조

```
01-basic/
├── docs/                      # 문서 디렉토리
│   ├── 01-setup.md           # 초기 설정 가이드
│   ├── 02-execution.md       # 실행 가이드
│   └── 03-cleanup.md         # 정리 가이드
├── main.tf                   # 주요 리소스 정의
├── variables.tf              # 입력 변수 선언
├── outputs.tf                # 출력 값 정의
├── versions.tf               # Terraform 및 Provider 버전
├── terraform.tfvars.example  # 변수 값 예시
├── .gitignore               # Git 제외 파일
└── README.md                # 현재 문서
```

## 🚀 실습 시작하기

### 1단계: 브랜치 체크아웃
```bash
git checkout 01-basic
```

### 2단계: 변수 파일 설정
```bash
# 예시 파일 복사
cp terraform.tfvars.example terraform.tfvars

# 에디터로 열어서 값 수정
vim terraform.tfvars
```

**terraform.tfvars 예시**:
```hcl
aws_region         = "ap-northeast-2"
environment        = "dev"
project_name       = "my-terraform-project"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
instance_type      = "t2.micro"
```

### 3단계: Terraform 초기화
```bash
terraform init
```

**출력 예시**:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.31.0...

Terraform has been successfully initialized!
```

### 4단계: 실행 계획 확인
```bash
terraform plan
```

**확인 사항**:
- 생성될 리소스 개수: `Plan: 7 to add`
- 각 리소스의 속성값이 올바른지 확인

### 5단계: 인프라 배포
```bash
terraform apply
```

**확인 메시지가 나타나면 `yes` 입력**

배포 완료 후 출력값 확인:
```
Outputs:

instance_id = "i-0123456789abcdef0"
instance_public_ip = "13.125.123.45"
vpc_id = "vpc-0123456789abcdef0"
web_url = "http://13.125.123.45"
```

### 6단계: 웹 서버 접속 확인
```bash
# 브라우저에서 접속
# http://[instance_public_ip]

# 또는 curl로 확인
curl $(terraform output -raw web_url)
```

### 7단계: 리소스 정리
```bash
terraform destroy
```

**확인 메시지가 나타나면 `yes` 입력**

## 💡 핵심 학습 포인트

### 1. Terraform 파일 구조

#### `versions.tf` - Provider 버전 관리
```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

**학습 포인트**:
- `required_version`: Terraform CLI 버전 지정
- `required_providers`: 사용할 Provider와 버전
- `provider` 블록: Provider 설정

---

#### `variables.tf` - 변수 선언
```hcl
variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition     = contains(["t2.micro", "t2.small"], var.instance_type)
    error_message = "프리티어 인스턴스 타입만 허용됩니다."
  }
}
```

**학습 포인트**:
- `description`: 변수 설명
- `type`: 데이터 타입 (string, number, bool, list, map)
- `default`: 기본값
- `validation`: 입력값 검증

---

#### `main.tf` - 리소스 정의
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}
```

**학습 포인트**:
- `resource "타입" "이름"`: 리소스 선언
- 변수 참조: `var.변수명`
- 다른 리소스 참조: `aws_vpc.main.id`
- 문자열 보간: `"${var.name}-suffix"`

---

#### `outputs.tf` - 출력값 정의
```hcl
output "instance_public_ip" {
  description = "EC2 인스턴스의 Public IP"
  value       = aws_instance.web.public_ip
}
```

**학습 포인트**:
- 중요한 정보를 사용자에게 표시
- 다른 모듈에서 참조 가능
- `terraform output` 명령으로 확인

---

### 2. Terraform 워크플로우

```
┌──────────┐
│   init   │  # Provider 다운로드, 초기화
└────┬─────┘
     │
     v
┌──────────┐
│   plan   │  # 변경 사항 미리보기
└────┬─────┘
     │
     v
┌──────────┐
│  apply   │  # 실제 리소스 생성/변경
└────┬─────┘
     │
     v
┌──────────┐
│   사용    │  # 인프라 사용
└────┬─────┘
     │
     v
┌──────────┐
│ destroy  │  # 리소스 삭제
└──────────┘
```

### 3. State 파일의 역할

**terraform.tfstate**:
- 현재 인프라의 실제 상태 저장
- Terraform이 변경사항을 추적하는 방법
- 팀 협업 시 공유 필요 (다음 브랜치에서 학습)

**⚠️ 주의**: State 파일에는 민감한 정보가 포함될 수 있으므로 Git에 커밋하지 않습니다!

## 📖 상세 가이드 문서

더 자세한 내용은 다음 문서를 참고하세요:

1. **[초기 설정 가이드](docs/01-setup.md)**
    - Terraform 설치
    - AWS CLI 설정
    - 프로젝트 초기화

2. **[실행 가이드](docs/02-execution.md)**
    - 명령어 상세 설명
    - 트러블슈팅
    - 유용한 팁

3. **[정리 가이드](docs/03-cleanup.md)**
    - 리소스 삭제 방법
    - 비용 방지
    - 로컬 파일 정리

## 🐛 자주 발생하는 문제

### 문제 1: AWS 자격증명 오류
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**해결방법**:
```bash
aws configure
# Access Key ID와 Secret Access Key 입력
```

---

### 문제 2: 리소스 이름 중복
```
Error: InvalidVpcID.NotFound
```

**해결방법**:
```bash
# State 파일이 있는지 확인
ls -la terraform.tfstate*

# 있다면 삭제 후 재시도
rm terraform.tfstate*
terraform apply
```

---

### 문제 3: Port 80 접속 안됨
```bash
# Security Group 확인
terraform state show aws_security_group.web

# 인스턴스 상태 확인
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
```

더 많은 트러블슈팅은 [실행 가이드](docs/02-execution.md)를 참고하세요.

## 💰 비용 안내

이 브랜치에서 생성하는 리소스는 모두 **AWS 프리티어 무료 범위** 내에서 사용 가능합니다:

- ✅ **t2.micro EC2**: 750시간/월 무료
- ✅ **VPC, Subnet, IGW**: 무료
- ✅ **Data Transfer**: 15GB/월 무료

**⚠️ 중요**: 실습 후 반드시 `terraform destroy`로 리소스를 삭제하세요!

## 📝 학습 노트 작성

학습한 내용을 정리해보세요:

```bash
# 개인 학습 노트 작성
mkdir -p learning-notes
cat > learning-notes/01-basic-notes.md << EOF
# 01-basic 학습 정리

## 배운 내용
- ...

## 어려웠던 점
- ...

## 다음에 공부할 것
- ...
EOF
```

## ✅ 학습 체크리스트

이 브랜치를 완료했다면 다음 항목을 확인하세요:

- [ ] Terraform 기본 명령어 이해 (init, plan, apply, destroy)
- [ ] HCL 문법 이해
- [ ] Variables 선언 및 사용
- [ ] Outputs 정의 및 활용
- [ ] AWS 리소스 간 의존성 이해
- [ ] State 파일의 역할 이해
- [ ] 실제 EC2 인스턴스 생성 및 접속 확인
- [ ] 리소스 정리 완료

## 🔄 다음 단계

축하합니다! Terraform 기초를 완료했습니다. 🎉

다음 브랜치로 이동하여 학습을 계속하세요:

```bash
# 리소스 정리 후
terraform destroy

# 다음 브랜치로 이동
git checkout 02-basic-localstack
```

**다음 학습 주제**: LocalStack을 사용한 로컬 개발 환경 구축

[← 메인 README로 돌아가기](https://github.com/solzip/terraform-aws-study) | [다음: 02-basic-localstack →](https://github.com/solzip/terraform-aws-study/tree/02-basic-localstack)

---

**작성일**: 2025-02-02  
**난이도**: 🟢 초급  
**예상 소요 시간**: 2-3시간
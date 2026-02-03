# 02-basic-localstack - 로컬 개발 환경

> 🟢 **난이도**: 초급 | **학습 시간**: 2시간 | **비용**: 💰 무료!

[← 메인 README로 돌아가기](../../) | [← 이전: 01-basic](../../tree/01-basic)

## 📚 이 브랜치에서 배우는 것

AWS 비용 걱정 없이 로컬 환경에서 Terraform을 실습합니다.

### 학습 목표
- ✅ LocalStack 설치 및 설정
- ✅ Docker Compose로 AWS 서비스 시뮬레이션
- ✅ 로컬 환경에서 Terraform 테스트
- ✅ 비용 없이 무제한 실습
- ✅ 오프라인 개발 환경 구축

### LocalStack이란?
- AWS 클라우드 서비스를 로컬에서 에뮬레이션하는 도구
- EC2, S3, DynamoDB, Lambda 등 주요 AWS 서비스 지원
- **완전 무료**로 테스트 가능
- CI/CD 파이프라인에서도 활용

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────┐
│         로컬 컴퓨터 (Your Machine)          │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   Docker Container (LocalStack)       │ │
│  │                                       │ │
│  │  Port 4566: AWS API Endpoint         │ │
│  │                                       │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │  Simulated AWS Services         │ │ │
│  │  │  - EC2                           │ │ │
│  │  │  - VPC                           │ │ │
│  │  │  - S3                            │ │ │
│  │  │  - DynamoDB                      │ │ │
│  │  │  - Lambda                        │ │ │
│  │  └─────────────────────────────────┘ │ │
│  └───────────────────────────────────────┘ │
│                    ↑                        │
│                    │                        │
│  ┌─────────────────────────────────────┐   │
│  │   Terraform                         │   │
│  │   Provider: AWS (localhost:4566)    │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## 📁 프로젝트 구조

```
02-basic-localstack/
├── README.md
├── docker-compose.yml          # LocalStack 설정
├── localstack/
│   ├── init-scripts/           # 초기화 스크립트
│   │   └── init.sh
│   └── README.md
├── main.tf                     # 리소스 정의 (01-basic과 동일)
├── variables.tf
├── outputs.tf
├── providers-localstack.tf     # LocalStack용 Provider
├── providers-aws.tf            # AWS 실제 환경용 (참고)
├── Makefile                    # 편의 명령어
└── .env.example                # 환경 변수 예시
```

## 🚀 실습 시작하기

### 사전 준비
- Docker 설치
- Docker Compose 설치
- Terraform 설치

### Step 1: LocalStack 실행

```bash
# Docker Compose로 LocalStack 시작
docker-compose up -d

# 실행 확인
docker-compose ps

# 로그 확인
docker-compose logs -f
```

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  localstack:
    image: localstack/localstack:latest
    container_name: terraform-localstack
    ports:
      - "4566:4566"  # LocalStack gateway
      - "4571:4571"  # LocalStack UI (선택사항)
    environment:
      - SERVICES=ec2,s3,dynamodb,iam,sts
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
      - DOCKER_HOST=unix:///var/run/docker.sock
    volumes:
      - "./localstack/data:/tmp/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./localstack/init-scripts:/docker-entrypoint-initaws.d"
```

### Step 2: Terraform 설정

**providers-localstack.tf**:
```hcl
provider "aws" {
  region                      = "ap-northeast-2"
  
  # LocalStack 자격증명 (테스트용)
  access_key                  = "test"
  secret_key                  = "test"
  
  # AWS API 검증 우회
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # LocalStack 엔드포인트
  endpoints {
    ec2            = "http://localhost:4566"
    s3             = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}
```

### Step 3: 리소스 배포

```bash
# Terraform 초기화
terraform init

# LocalStack 확인
curl http://localhost:4566/_localstack/health

# 배포
terraform plan
terraform apply -auto-approve

# 생성된 리소스 확인
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs
aws --endpoint-url=http://localhost:4566 s3 ls
```

### Step 4: 정리

```bash
# Terraform 리소스 삭제
terraform destroy -auto-approve

# LocalStack 중지
docker-compose down

# 데이터 삭제 (완전 초기화)
docker-compose down -v
rm -rf localstack/data
```

## 💡 핵심 학습 포인트

### 1. LocalStack vs 실제 AWS

| 항목 | LocalStack | 실제 AWS |
|------|-----------|----------|
| 비용 | 무료 | 사용량 과금 |
| 속도 | 매우 빠름 | 네트워크 지연 |
| 인터넷 | 불필요 | 필수 |
| 제약사항 | 일부 기능 제한 | 전체 기능 |
| 용도 | 개발/테스트 | 프로덕션 |

### 2. LocalStack 활용 시나리오

**개발 중**:
```bash
# LocalStack에서 빠르게 테스트
terraform apply  # 5초 소요

# 코드 수정 후 다시 테스트
terraform destroy && terraform apply  # 비용 걱정 없음
```

**배포 전 검증**:
```bash
# 1. LocalStack에서 테스트
terraform apply -var-file=test.tfvars

# 2. 문제없으면 실제 AWS에 배포
terraform apply -var-file=prod.tfvars
```

**CI/CD 파이프라인**:
```yaml
# .github/workflows/test.yml
- name: Start LocalStack
  run: docker-compose up -d

- name: Test Terraform
  run: |
    terraform init
    terraform plan
    terraform apply -auto-approve
```

### 3. Makefile로 편리하게 사용

**Makefile**:
```makefile
.PHONY: start stop init plan apply destroy clean

# LocalStack 시작
start:
	docker-compose up -d
	@echo "Waiting for LocalStack..."
	@sleep 5

# LocalStack 중지
stop:
	docker-compose down

# Terraform 초기화
init: start
	terraform init

# Terraform Plan
plan: init
	terraform plan

# Terraform Apply
apply: init
	terraform apply -auto-approve

# Terraform Destroy
destroy:
	terraform destroy -auto-approve

# 완전 정리
clean: destroy stop
	rm -rf .terraform
	rm -rf localstack/data
	rm -f terraform.tfstate*

# 전체 테스트
test: clean apply
	@echo "Testing completed!"
	@$(MAKE) destroy
```

**사용 예시**:
```bash
# 전체 테스트 자동화
make test

# 단계별 실행
make start   # LocalStack 시작
make apply   # 리소스 생성
make destroy # 리소스 삭제
make clean   # 완전 정리
```

## 🔍 LocalStack 명령어

### 헬스 체크
```bash
# LocalStack 상태 확인
curl http://localhost:4566/_localstack/health | jq

# 출력 예시:
# {
#   "services": {
#     "ec2": "running",
#     "s3": "running",
#     "dynamodb": "running"
#   }
# }
```

### AWS CLI 사용
```bash
# 기본 사용법
aws --endpoint-url=http://localhost:4566 [service] [command]

# VPC 목록
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs

# S3 버킷 목록
aws --endpoint-url=http://localhost:4566 s3 ls

# S3 버킷 생성
aws --endpoint-url=http://localhost:4566 s3 mb s3://test-bucket

# DynamoDB 테이블 목록
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

### 별칭 설정 (편의)
```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
alias awslocal='aws --endpoint-url=http://localhost:4566'

# 사용
awslocal ec2 describe-vpcs
awslocal s3 ls
```

## 🐛 트러블슈팅

### 문제 1: LocalStack이 시작되지 않음
```bash
# Docker 실행 확인
docker ps

# LocalStack 로그 확인
docker-compose logs localstack

# 재시작
docker-compose restart localstack
```

### 문제 2: Terraform이 LocalStack에 연결 안됨
```bash
# LocalStack 엔드포인트 확인
curl http://localhost:4566/_localstack/health

# 방화벽 확인 (macOS)
sudo lsof -i :4566

# Provider 설정 확인
terraform providers
```

### 문제 3: 리소스가 생성되지 않음
```bash
# LocalStack에서 지원하는 서비스 확인
curl http://localhost:4566/_localstack/health

# Pro 기능이 필요한 경우 무료 버전에서는 제한됨
# 예: ECS, EKS 등은 Pro 버전 필요
```

## 💰 비용 절감 효과

### 실습 시나리오 비교

| 작업 | LocalStack | 실제 AWS |
|------|-----------|----------|
| EC2 1시간 테스트 | $0 | $0.012 |
| 10번 재생성 | $0 | $0.12 |
| 하루 종일 실습 | $0 | $0.288 |
| 한 달 학습 | $0 | $8.64 |

**결론**: LocalStack으로 한 달 학습 시 약 $10 절약!

## ✅ 학습 체크리스트

- [ ] Docker Compose로 LocalStack 실행
- [ ] Terraform Provider를 LocalStack 엔드포인트로 설정
- [ ] 로컬에서 VPC, EC2 등 리소스 생성
- [ ] AWS CLI로 LocalStack 리소스 확인
- [ ] Makefile로 자동화 경험
- [ ] LocalStack과 실제 AWS의 차이 이해
- [ ] CI/CD 파이프라인에서 활용 방법 이해

## 🔄 다음 단계

LocalStack으로 로컬 개발 환경을 마스터했습니다! 🎉

### 다음 브랜치: 멀티 환경 관리
```bash
# LocalStack 정리
make clean

# 다음 브랜치로 이동
git checkout 03-multi-environment
```

03-multi-environment에서는:
- Dev, Staging, Prod 환경 분리
- 환경별 변수 관리
- Workspace 활용

[← 이전: 01-basic](../../tree/01-basic) | [다음: 03-multi-environment →](../../tree/03-multi-environment)

---

**작성일**: 2025-02-02  
**난이도**: 🟢 초급  
**비용**: 💰 완전 무료!
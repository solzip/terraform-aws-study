# Makefile for LocalStack Terraform Project
# 자주 사용하는 명령어를 간편하게 실행

.PHONY: help start stop restart logs health init validate plan apply destroy clean test all

# 기본 타겟 - help 출력
.DEFAULT_GOAL := help

# 도움말
help: ## 사용 가능한 명령어 목록 표시
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  LocalStack Terraform 프로젝트 명령어"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ==========================================
# LocalStack 관리
# ==========================================

start: ## LocalStack 시작
	@echo "🚀 Starting LocalStack..."
	docker-compose up -d
	@echo "⏳ Waiting for LocalStack to be ready..."
	@sleep 5
	@$(MAKE) health

stop: ## LocalStack 중지
	@echo "🛑 Stopping LocalStack..."
	docker-compose down

restart: ## LocalStack 재시작
	@echo "🔄 Restarting LocalStack..."
	@$(MAKE) stop
	@$(MAKE) start

logs: ## LocalStack 로그 확인 (실시간)
	docker-compose logs -f

health: ## LocalStack 상태 확인
	@echo "🏥 Checking LocalStack health..."
	@curl -s http://localhost:4566/_localstack/health | jq . || \
		echo "❌ LocalStack is not running or jq is not installed"

ps: ## 실행 중인 컨테이너 확인
	docker-compose ps

# ==========================================
# Terraform 작업
# ==========================================

init: start ## Terraform 초기화 (LocalStack 자동 시작)
	@echo "📦 Initializing Terraform..."
	terraform init

validate: ## Terraform 구성 검증
	@echo "✅ Validating Terraform configuration..."
	terraform validate

fmt: ## Terraform 코드 포맷팅
	@echo "🎨 Formatting Terraform code..."
	terraform fmt -recursive

plan: init ## Terraform 실행 계획 확인
	@echo "📋 Planning Terraform changes..."
	terraform plan

apply: init ## Terraform 적용 (자동 승인)
	@echo "🚀 Applying Terraform configuration..."
	terraform apply -auto-approve

destroy: ## Terraform 리소스 삭제
	@echo "💥 Destroying Terraform resources..."
	terraform destroy -auto-approve

# ==========================================
# 유틸리티
# ==========================================

clean: destroy stop ## 모든 리소스 정리 (Terraform + LocalStack)
	@echo "🧹 Cleaning up..."
	rm -rf .terraform
	rm -rf .terraform.lock.hcl
	rm -f terraform.tfstate*
	rm -rf localstack/data/*
	@echo "✨ Cleanup complete!"

reset: clean ## 완전 초기화 (clean + Docker 이미지 삭제)
	@echo "🔄 Resetting everything..."
	docker-compose down -v --rmi local
	@echo "✨ Reset complete!"

test: all ## 전체 테스트 (시작 → 적용 → 확인 → 삭제)
	@echo "🧪 Running full test..."
	@$(MAKE) clean
	@$(MAKE) apply
	@echo "⏳ Waiting 10 seconds..."
	@sleep 10
	@$(MAKE) check
	@$(MAKE) destroy
	@echo "✅ Test complete!"

all: start init apply ## 전체 작업 실행 (시작 → 초기화 → 적용)
	@echo "✅ All tasks completed!"

# ==========================================
# AWS CLI (LocalStack)
# ==========================================

aws-config: ## AWS CLI 설정 (LocalStack용)
	@echo "⚙️  Configuring AWS CLI for LocalStack..."
	@echo "[profile localstack]" > ~/.aws/config
	@echo "region = ap-northeast-2" >> ~/.aws/config
	@echo "output = json" >> ~/.aws/config
	@echo "[localstack]" > ~/.aws/credentials
	@echo "aws_access_key_id = test" >> ~/.aws/credentials
	@echo "aws_secret_access_key = test" >> ~/.aws/credentials
	@echo "✅ AWS CLI configured for LocalStack"

list-vpcs: ## VPC 목록 확인
	@aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table

list-instances: ## EC2 인스턴스 목록 확인
	@aws --endpoint-url=http://localhost:4566 ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table

list-s3: ## S3 버킷 목록 확인
	@aws --endpoint-url=http://localhost:4566 s3 ls

# ==========================================
# 확인 및 디버깅
# ==========================================

check: ## 생성된 리소스 확인
	@echo "🔍 Checking created resources..."
	@echo "\n=== Terraform State ==="
	@terraform state list || echo "No resources in state"
	@echo "\n=== VPCs ==="
	@$(MAKE) list-vpcs || echo "Failed to list VPCs"
	@echo "\n=== Instances ==="
	@$(MAKE) list-instances || echo "Failed to list instances"

output: ## Terraform 출력 확인
	@terraform output

shell: ## LocalStack 컨테이너 쉘 접속
	docker-compose exec localstack /bin/bash

# ==========================================
# 개발 편의
# ==========================================

watch-logs: ## 로그 실시간 모니터링 (컬러)
	docker-compose logs -f --tail=100 | grep --color=auto -E 'ERROR|WARNING|INFO|$$'

install-deps: ## 필수 도구 설치 확인
	@echo "🔧 Checking dependencies..."
	@command -v docker >/dev/null 2>&1 || echo "❌ Docker not found"
	@command -v docker-compose >/dev/null 2>&1 || echo "❌ Docker Compose not found"
	@command -v terraform >/dev/null 2>&1 || echo "❌ Terraform not found"
	@command -v aws >/dev/null 2>&1 || echo "❌ AWS CLI not found"
	@command -v jq >/dev/null 2>&1 || echo "❌ jq not found (optional)"
	@echo "✅ Dependency check complete"

# ==========================================
# 사용 예시
# ==========================================
#
# 기본 워크플로우:
#   1. make start      # LocalStack 시작
#   2. make apply      # 인프라 배포
#   3. make check      # 리소스 확인
#   4. make destroy    # 리소스 삭제
#   5. make stop       # LocalStack 중지
#
# 빠른 테스트:
#   make test          # 전체 자동화 테스트
#
# 전체 초기화:
#   make clean         # 모든 리소스 정리
#   make reset         # 완전 초기화
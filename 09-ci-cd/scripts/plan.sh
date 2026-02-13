#!/bin/bash
# ==========================================
# plan.sh - 로컬 Plan 실행 스크립트
# ==========================================
#
# 이 스크립트의 역할:
#   로컬에서 terraform plan을 실행합니다.
#   환경을 선택하여 각 환경의 변경 사항을 확인할 수 있습니다.
#
# 사용법:
#   bash scripts/plan.sh           # 기본값: dev
#   bash scripts/plan.sh dev       # dev 환경
#   bash scripts/plan.sh staging   # staging 환경
#   bash scripts/plan.sh prod      # prod 환경
#
# 사전 요구사항:
#   - AWS 자격증명 설정 (aws configure 또는 환경변수)
#   - Terraform 설치

set -e

# 환경 파라미터 (기본값: dev)
ENVIRONMENT="${1:-dev}"

# 유효한 환경인지 확인
case "$ENVIRONMENT" in
    dev|staging|prod)
        echo "Environment: $ENVIRONMENT"
        ;;
    *)
        echo "❌ Invalid environment: $ENVIRONMENT"
        echo "Usage: $0 [dev|staging|prod]"
        exit 1
        ;;
esac

echo "============================================"
echo "  Terraform Plan - ${ENVIRONMENT}"
echo "============================================"
echo ""

# AWS 자격증명 확인
echo "Checking AWS credentials..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    echo "  AWS Account: ${ACCOUNT_ID}"
else
    echo "❌ AWS credentials not configured!"
    echo "Run 'aws configure' or set AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY"
    exit 1
fi
echo ""

# Terraform 초기화
echo "Initializing Terraform..."
terraform init -backend=false > /dev/null 2>&1
echo ""

# Plan 실행
echo "Running terraform plan..."
echo "============================================"
terraform plan \
    -var="environment=${ENVIRONMENT}" \
    -input=false

echo ""
echo "============================================"
echo "Plan complete for '${ENVIRONMENT}' environment."
echo "To apply: terraform apply -var=\"environment=${ENVIRONMENT}\""
echo "============================================"

# 정리
rm -rf .terraform .terraform.lock.hcl

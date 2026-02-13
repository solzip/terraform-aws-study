#!/bin/bash
# ==========================================
# validate.sh - 로컬 검증 스크립트
# ==========================================
#
# 이 스크립트의 역할:
#   GitHub에 Push하기 전에 로컬에서 코드 품질을 검증합니다.
#   CI/CD 파이프라인에서 실패하는 것보다
#   로컬에서 미리 확인하는 것이 훨씬 빠릅니다.
#
# 사용법:
#   cd 09-ci-cd
#   bash scripts/validate.sh
#
# 또는 실행 권한 부여 후:
#   chmod +x scripts/validate.sh
#   ./scripts/validate.sh

set -e  # 에러 발생 시 즉시 중단

echo "============================================"
echo "  Terraform Local Validation"
echo "============================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 결과 카운터
PASS=0
FAIL=0

# ==========================================
# Step 1: Terraform 설치 확인
# ==========================================
echo "Step 1: Checking Terraform installation..."
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['terraform_version'])" 2>/dev/null || terraform version | head -1)
    echo -e "  ${GREEN}✅ Terraform found: ${TF_VERSION}${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ Terraform not found! Install from https://www.terraform.io/downloads${NC}"
    FAIL=$((FAIL + 1))
    exit 1
fi
echo ""

# ==========================================
# Step 2: 코드 포맷 검사
# ==========================================
echo "Step 2: Checking code format..."
if terraform fmt -check -recursive -diff > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Format check passed${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ Format check failed!${NC}"
    echo -e "  ${YELLOW}Fix: terraform fmt -recursive${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# ==========================================
# Step 3: Terraform 초기화
# ==========================================
echo "Step 3: Initializing Terraform..."
if terraform init -backend=false > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Init successful${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ Init failed!${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# ==========================================
# Step 4: 문법 검증
# ==========================================
echo "Step 4: Validating configuration..."
VALIDATE_OUTPUT=$(terraform validate -no-color 2>&1)
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✅ Validation passed${NC}"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ Validation failed!${NC}"
    echo "  $VALIDATE_OUTPUT"
    FAIL=$((FAIL + 1))
fi
echo ""

# ==========================================
# Step 5: .terraform 정리
# ==========================================
echo "Step 5: Cleaning up..."
rm -rf .terraform .terraform.lock.hcl
echo -e "  ${GREEN}✅ Cleaned up .terraform directory${NC}"
echo ""

# ==========================================
# 결과 요약
# ==========================================
echo "============================================"
echo "  Validation Results"
echo "============================================"
echo -e "  Passed: ${GREEN}${PASS}${NC}"
echo -e "  Failed: ${RED}${FAIL}${NC}"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}Some checks failed. Please fix before pushing.${NC}"
    exit 1
else
    echo -e "${GREEN}All checks passed! Ready to push.${NC}"
    exit 0
fi

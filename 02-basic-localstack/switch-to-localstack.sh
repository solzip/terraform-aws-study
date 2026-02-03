#!/bin/bash

# LocalStack으로 전환하는 스크립트

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Switching to LocalStack..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 현재 Provider 파일 백업 (있다면)
if [ -f "providers.tf" ]; then
    echo "📦 Backing up current providers.tf to providers-aws.tf..."
    mv providers.tf providers-aws.tf
fi

# LocalStack Provider 활성화 (백업에서 복원)
if [ -f "providers-localstack.tf.bak" ]; then
    echo "✅ Restoring providers-localstack.tf..."
    mv providers-localstack.tf.bak providers-localstack.tf
fi

# Terraform 재초기화
echo "🔄 Reinitializing Terraform..."
rm -rf .terraform .terraform.lock.hcl
terraform init

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Switched to LocalStack!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Start LocalStack: make start"
echo "  2. Apply infrastructure: terraform apply"
echo "  3. Check resources: make check"
echo ""
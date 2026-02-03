#!/bin/bash

# 실제 AWS로 전환하는 스크립트

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Switching to AWS..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# LocalStack Provider 백업
if [ -f "providers-localstack.tf" ]; then
    echo "📦 Backing up providers-localstack.tf..."
    mv providers-localstack.tf providers-localstack.tf.bak
fi

# AWS Provider 활성화
if [ -f "providers-aws.tf" ]; then
    echo "✅ Activating providers-aws.tf..."
    mv providers-aws.tf providers.tf

    # providers.tf 주석 해제 (간단한 방법)
    echo "⚠️  Note: You need to uncomment the provider block in providers.tf"
else
    echo "❌ Error: providers-aws.tf not found!"
    exit 1
fi

# AWS 자격증명 확인
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "⚠️  Warning: AWS credentials not configured!"
    echo "   Please run: aws configure"
fi

# Terraform 재초기화
echo "🔄 Reinitializing Terraform..."
rm -rf .terraform .terraform.lock.hcl
terraform init

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Switched to AWS!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  IMPORTANT:"
echo "  1. Uncomment provider block in providers.tf"
echo "  2. Configure AWS credentials: aws configure"
echo "  3. Verify configuration: terraform plan"
echo "  4. ⚠️  AWS resources will incur costs!"
echo "  5. Remember to destroy resources when done!"
echo ""
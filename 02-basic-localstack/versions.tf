# Terraform 및 Provider 버전 관리

terraform {
  # Terraform 최소 버전
  required_version = ">= 1.0"

  # 필요한 Provider
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 참고: Provider 설정은 providers-localstack.tf에 정의되어 있습니다
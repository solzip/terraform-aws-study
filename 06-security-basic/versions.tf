# ==========================================
# versions.tf - Terraform 및 Provider 버전 관리
# ==========================================
#
# Terraform CLI와 AWS Provider의 버전을 지정합니다.
# 팀원 모두 동일한 환경에서 작업할 수 있도록 보장합니다.

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # random provider: 비밀번호 등 랜덤 값 생성에 사용
    # Secrets Manager에 저장할 초기 비밀번호 생성 목적
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# AWS Provider 설정
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Environment = var.environment
      CreatedBy   = "06-security-basic"
    }
  }
}

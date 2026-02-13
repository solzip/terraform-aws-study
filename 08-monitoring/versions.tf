# ==========================================
# versions.tf - Terraform 및 Provider 버전 관리
# ==========================================
#
# 모니터링 브랜치에서는 AWS Provider만 사용합니다.
# CloudWatch, SNS, CloudTrail 모두 AWS Provider에 포함되어 있습니다.

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Random Provider
    # S3 버킷 이름에 고유 접미사를 추가하는 데 사용
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Branch      = "08-monitoring"
    }
  }
}

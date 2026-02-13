# versions.tf
# Terraform 및 Provider 버전 관리

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider 기본 설정
provider "aws" {
  region = var.aws_region

  # 모든 리소스에 자동 추가될 기본 태그
  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Environment = var.environment
      CreatedBy   = "03-multi-environment"
    }
  }
}

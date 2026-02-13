# ==========================================
# versions.tf - Terraform 및 Provider 버전 관리
# ==========================================
#
# CI/CD 환경에서는 버전 고정이 특히 중요합니다.
# 로컬과 CI에서 동일한 버전을 사용해야
# "로컬에서는 되는데 CI에서 안 돼요" 문제를 방지할 수 있습니다.
#
# .terraform.lock.hcl 파일도 Git에 포함하는 것을 권장합니다.
# 이 파일은 Provider의 정확한 버전과 해시를 기록합니다.

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # CI/CD 환경에서는 S3 Backend을 사용하는 것이 일반적입니다.
  # 여러 워크플로우가 동시에 실행될 때 State Lock이 중요합니다.
  #
  # 학습용으로는 로컬 Backend을 사용합니다.
  # 실제 환경에서는 아래와 같이 S3 Backend을 설정하세요:
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "09-ci-cd/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Branch      = "09-ci-cd"
      DeployedBy  = "GitHubActions"
    }
  }
}

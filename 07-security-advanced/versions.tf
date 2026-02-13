# ==========================================
# versions.tf - Terraform 및 Provider 버전 관리
# ==========================================
#
# 이 파일의 역할:
#   Terraform 엔진과 AWS Provider의 최소 버전을 지정합니다.
#   팀원 모두가 동일한 버전으로 작업하도록 보장하여
#   "내 PC에서는 되는데..."라는 문제를 방지합니다.
#
# 07-security-advanced에서 추가된 Provider:
#   - random: 랜덤 비밀번호 생성용
#   - archive: Lambda 함수 ZIP 패키징용

terraform {
  # Terraform 엔진 최소 버전
  # 1.0 이상이면 사용 가능하지만, 최신 기능을 위해 1.0 이상 권장
  required_version = ">= 1.0"

  required_providers {
    # AWS Provider
    # ~> 5.0: 5.x.x 버전만 허용 (5.0.0 ~ 5.99.99)
    # 메이저 버전(6.x)은 호환성이 깨질 수 있으므로 제외
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Random Provider
    # 안전한 랜덤 비밀번호를 생성하는 데 사용
    # Secrets Manager에 저장할 DB 비밀번호 생성에 활용
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }

    # Archive Provider
    # Lambda 함수 코드를 ZIP 파일로 패키징하는 데 사용
    # Secrets Manager 자동 로테이션 Lambda에 필요
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# ==========================================
# AWS Provider 설정
# ==========================================
#
# default_tags:
#   모든 AWS 리소스에 자동으로 태그를 추가합니다.
#   각 리소스마다 태그를 반복 작성할 필요가 없어 편리합니다.
#   비용 추적, 리소스 관리, 보안 감사에 활용됩니다.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Branch      = "07-security-advanced"
    }
  }
}

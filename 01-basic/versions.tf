# versions.tf
# Terraform 및 Provider 버전 관리 파일

# versions.tf 를 통해 Terraform 과 Provider 버전을 먼저 고정해야 다른 작업이 가능하다!

# Terraform 자체의 최소 버전 요구사항
terraform {
  # Terraform CLI 버전 - 1.0 이상 사용
  # 1.0 버전 이하에서는 실행되지 않는다
  required_version = ">= 1.0"

  # 사용할 provider 들과 그 버전을 명시
  required_providers {
    # AWS Providers {
    aws = {
      source = "hashicorp/aws"      # Provider 소스 ( 공식 레지스트리 )
      version = "~> 5.0"            # 5.x 버전 사용 ( 5.0 이상, 6.0 미만 )
        # ~> : pessimistic constraint operator
        # 5.0 이상의 마이너 버전 업데이트는 허용하지만 메이저
    }
  }
}

# AWS Provider 기본 설정
provider "aws" {
  # 라소스를 생성할 AWS 리전
  region = var.aws_region     # 변수로 받아서 유연하게 변경 가능하도록 설정

  # 생성되는 모든 리소스에 자동으로 추가될 태그
  # - 리소스 관리 및 비용 추적에 유리
  default_tags {
    tags = {
      Project       = "terraform-basic"   # 프로젝트 이름
      ManagedBy     = "Terraform"         # Terraform 으로 관리됨을 표시
      Environment   = var.environment        # 환경 구분 (dev, prod 등)
      CreatedBy     = "01-basic-branch"      # 어느 브랜치에서 생성되었는지
    }
  }
}
# ==========================================
# versions.tf - Terraform 및 Provider 버전 관리
# ==========================================
#
# 이 파일은 Terraform CLI와 AWS Provider의 버전을 지정합니다.
# 팀원 모두가 동일한 버전을 사용하도록 보장하는 역할을 합니다.
#
# 왜 버전을 고정하는가?
# - Terraform이나 Provider가 업데이트되면 동작이 달라질 수 있음
# - 팀원 간 버전 차이로 인한 오류 방지
# - 프로덕션 환경의 안정성 보장

terraform {
  # Terraform CLI 최소 버전 요구사항
  # ">= 1.0" : 1.0 이상이면 모두 허용 (1.0, 1.5, 1.9 등)
  required_version = ">= 1.0"

  # 사용할 Provider(플러그인) 목록과 버전
  required_providers {
    aws = {
      # Provider 소스 경로 (Terraform Registry에서 다운로드)
      source = "hashicorp/aws"

      # "~> 5.0" : 5.x 버전만 허용 (5.0 이상, 6.0 미만)
      # 이를 "pessimistic constraint"라고 합니다
      # 마이너 업데이트(5.1, 5.2...)는 허용하지만
      # 메이저 업데이트(6.0)는 차단하여 호환성을 보장합니다
      version = "~> 5.0"
    }
  }
}

# ==========================================
# AWS Provider 기본 설정
# ==========================================
#
# provider 블록은 AWS에 접속하기 위한 설정을 정의합니다.
# - region: 리소스를 생성할 AWS 리전
# - default_tags: 모든 리소스에 자동으로 추가되는 태그

provider "aws" {
  # 리소스를 생성할 AWS 리전
  # var.aws_region 변수로 받아서 유연하게 변경 가능
  region = var.aws_region

  # 이 Provider로 생성하는 모든 리소스에 자동 추가되는 태그
  # 각 리소스의 tags 블록에 일일이 추가할 필요 없이
  # 여기서 한번 설정하면 전체 적용됩니다
  default_tags {
    tags = {
      Project     = var.project_name  # 프로젝트 식별
      ManagedBy   = "Terraform"       # IaC로 관리됨을 표시
      Environment = var.environment   # 환경 구분 (dev/staging/prod)
      CreatedBy   = "05-remote-state" # 어느 브랜치에서 생성했는지
    }
  }
}

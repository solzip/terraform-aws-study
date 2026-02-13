# ==========================================
# main.tf - 프로덕션 메인 구성 파일
# ==========================================
#
# 이 파일의 역할:
#   모든 모듈을 호출하고 연결하는 "오케스트레이터" 역할입니다.
#   직접 리소스를 만들지 않고, 모듈을 통해 생성합니다.
#   이것이 프로덕션 코드의 핵심 패턴입니다.
#
# 프로덕션 아키텍처 원칙:
#   1. 모든 리소스는 모듈을 통해 생성 (재사용성)
#   2. 모듈 간 의존성은 출력값으로 연결 (느슨한 결합)
#   3. locals로 공통 로직 집중 관리 (DRY 원칙)
#   4. 조건부 리소스로 환경별 차이 처리

# ==========================================
# 데이터 소스
# ==========================================
# 데이터 소스는 AWS에서 정보를 "읽어오는" 것입니다.
# 리소스를 생성하지 않으므로 안전합니다.

# 현재 AWS 계정 정보 조회
# 계정 ID를 태그나 리소스 이름에 사용할 수 있습니다
data "aws_caller_identity" "current" {}

# 사용 가능한 가용영역 조회
# 하드코딩 대신 동적으로 조회하면 리전 변경 시에도 동작합니다
data "aws_availability_zones" "available" {
  state = "available"
}

# 최신 Amazon Linux 2023 AMI 자동 조회
# AMI ID를 하드코딩하면 리전/시간에 따라 달라지므로
# 항상 최신 AMI를 자동으로 가져오는 것이 좋습니다
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==========================================
# Locals (로컬 변수)
# ==========================================
# locals는 반복되는 표현식을 한 곳에서 관리합니다.
# "계산된 값"이나 "조합된 값"을 정의하는 데 사용합니다.
locals {
  # ------------------------------------------
  # 리소스 이름 접두사
  # ------------------------------------------
  # 모든 리소스 이름에 "프로젝트-환경" 접두사를 붙입니다.
  # 예: "tf-study-dev-vpc", "tf-study-prod-ec2"
  name_prefix = "${var.project_name}-${var.environment}"

  # ------------------------------------------
  # 프로덕션 환경 판별
  # ------------------------------------------
  # prod 환경에서는 더 엄격한 설정을 적용합니다.
  # 예: 상세 모니터링 활성화, 삭제 보호 등
  is_production = var.environment == "prod"

  # ------------------------------------------
  # 공통 태그
  # ------------------------------------------
  # 모든 리소스에 적용할 표준 태그입니다.
  # Provider의 default_tags와 합쳐져서 최종 태그가 됩니다.
  common_tags = merge(
    {
      Name        = local.name_prefix
      Environment = var.environment
      AccountId   = data.aws_caller_identity.current.account_id
    },
    var.additional_tags
  )

  # ------------------------------------------
  # 환경별 설정 맵
  # ------------------------------------------
  # 환경에 따라 달라지는 설정을 한 곳에서 관리합니다.
  # 새로운 환경별 설정이 필요하면 여기에 추가합니다.
  env_config = {
    dev = {
      instance_count    = 1
      enable_monitoring = false
      log_retention     = 7 # 7일
    }
    staging = {
      instance_count    = 2
      enable_monitoring = true
      log_retention     = 30 # 30일
    }
    prod = {
      instance_count    = 3
      enable_monitoring = true
      log_retention     = 90 # 90일
    }
  }
}

# ==========================================
# 모듈 호출: VPC 네트워크
# ==========================================
# VPC 모듈은 네트워크 인프라 전체를 생성합니다.
# 모듈을 사용하면 복잡한 네트워크 설정을 캡슐화할 수 있습니다.
#
# 전달하는 값:
#   name_prefix  → 리소스 이름 접두사
#   vpc_cidr     → VPC 주소 범위
#   subnet_cidrs → 서브넷 주소 범위 목록
#   azs          → 가용영역 목록
#   tags         → 공통 태그
module "vpc" {
  source = "./modules/vpc"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
  common_tags         = local.common_tags
}

# ==========================================
# 모듈 호출: Security (보안 그룹 + IAM)
# ==========================================
# 보안 모듈은 Security Group과 IAM Role을 생성합니다.
# VPC ID가 필요하므로 VPC 모듈의 출력값을 참조합니다.
#
# 모듈 간 연결:
#   module.vpc.vpc_id → 이 모듈의 vpc_id
# 이것이 "모듈 간 느슨한 결합"의 핵심입니다.
module "security" {
  source = "./modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  environment       = var.environment
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  common_tags       = local.common_tags
}

# ==========================================
# 모듈 호출: EC2 인스턴스
# ==========================================
# EC2 모듈은 컴퓨팅 인스턴스를 생성합니다.
# VPC 모듈의 서브넷 ID와 Security 모듈의 SG ID가 필요합니다.
#
# 모듈 간 연결 흐름:
#   module.vpc.public_subnet_ids    → EC2가 배치될 서브넷
#   module.security.web_sg_id       → EC2에 적용할 보안 그룹
#   module.security.ec2_instance_profile_name → EC2에 할당할 IAM 역할
#
# 이렇게 모듈의 출력값으로 연결하면:
#   - 각 모듈을 독립적으로 테스트 가능
#   - 모듈 교체가 쉬움 (인터페이스만 맞추면 됨)
#   - 의존성이 명시적으로 드러남
module "ec2" {
  source = "./modules/ec2"

  name_prefix                = local.name_prefix
  environment                = var.environment
  instance_type              = var.instance_type
  instance_count             = var.instance_count
  ami_id                     = data.aws_ami.amazon_linux.id
  subnet_ids                 = module.vpc.public_subnet_ids
  security_group_id          = module.security.web_sg_id
  instance_profile_name      = module.security.ec2_instance_profile_name
  enable_detailed_monitoring = var.enable_detailed_monitoring || local.is_production
  common_tags                = local.common_tags
}

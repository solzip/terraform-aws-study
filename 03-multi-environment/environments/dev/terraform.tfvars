# environments/dev/terraform.tfvars
# Dev 환경 변수 설정
# - 최소 사양으로 비용 절감
# - 빠른 테스트 및 개발 목적

environment  = "dev"
project_name = "multi-env"
aws_region   = "ap-northeast-2"

# 네트워크 - Dev는 단일 서브넷
vpc_cidr            = "10.2.0.0/16"
public_subnet_cidrs = ["10.2.1.0/24"]

# EC2 - 최소 사양
instance_type  = "t2.micro"
instance_count = 1

# 기능 - 개발 환경에서는 비활성화
enable_backup     = false
enable_monitoring = false

# 보안 - Dev에서는 모든 IP 허용 (학습 목적)
allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
allowed_http_cidr_blocks = ["0.0.0.0/0"]

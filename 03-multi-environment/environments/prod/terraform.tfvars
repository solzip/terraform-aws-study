# environments/prod/terraform.tfvars
# Production 환경 변수 설정
# - 고가용성 및 안정성 최우선
# - Multi-AZ, 백업, 모니터링 모두 활성화

environment  = "prod"
project_name = "multi-env"
aws_region   = "ap-northeast-2"

# 네트워크 - 3개 가용 영역 (Multi-AZ)
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

# EC2 - 고사양, 3대 운영
instance_type  = "t3.medium"
instance_count = 3

# 기능 - 모든 기능 활성화
enable_backup     = true
enable_monitoring = true

# 보안 - Prod에서는 특정 IP만 허용 권장
# 아래는 예시이며 실제 운영 시 사무실/VPN IP로 제한
allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
allowed_http_cidr_blocks = ["0.0.0.0/0"]

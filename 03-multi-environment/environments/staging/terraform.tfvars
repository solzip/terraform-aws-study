# environments/staging/terraform.tfvars
# Staging 환경 변수 설정
# - Prod와 유사한 구성으로 사전 검증
# - 이중화 구성으로 안정성 테스트

environment  = "staging"
project_name = "multi-env"
aws_region   = "ap-northeast-2"

# 네트워크 - 2개 가용 영역
vpc_cidr            = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]

# EC2 - 중간 사양, 이중화
instance_type  = "t2.small"
instance_count = 2

# 기능 - 백업 활성화
enable_backup     = true
enable_monitoring = false

# 보안
allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
allowed_http_cidr_blocks = ["0.0.0.0/0"]

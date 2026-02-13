# ==========================================
# dev 환경 변수 설정
# ==========================================
#
# 개발 환경 특성:
#   - 최소 비용 (t2.micro, 인스턴스 1개)
#   - 빠른 배포/삭제 사이클
#   - 상세 모니터링 비활성화
#   - SSH 접근 허용 (개발 편의성)

environment  = "dev"
project_name = "tf-study"
aws_region   = "ap-northeast-2"

# 네트워크: dev 전용 대역 (10.1.x.x)
vpc_cidr            = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
availability_zones  = ["ap-northeast-2a", "ap-northeast-2c"]

# EC2: 최소 사양
instance_type  = "t2.micro"
instance_count = 1

# 보안: dev에서는 SSH 허용 (실제 사용 시 본인 IP로 변경)
# allowed_ssh_cidrs = ["203.0.113.0/32"]  # 본인 IP 입력
allowed_ssh_cidrs = []

# 모니터링: 기본 (5분 간격)
enable_detailed_monitoring = false

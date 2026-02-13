# ==========================================
# prod (프로덕션) 환경 변수 설정
# ==========================================
#
# 프로덕션 환경 특성:
#   - 고가용성 (인스턴스 3대, 2개 가용영역)
#   - 보안 강화 (SSH 완전 차단)
#   - 상세 모니터링 필수
#   - 비용 최적화된 인스턴스 타입 (t3)

environment  = "prod"
project_name = "tf-study"
aws_region   = "ap-northeast-2"

# 네트워크: prod 전용 대역 (10.0.x.x)
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
availability_zones  = ["ap-northeast-2a", "ap-northeast-2c"]

# EC2: 프로덕션 사양, 3대 (2개 AZ에 분산)
instance_type  = "t3.medium"
instance_count = 3

# 보안: SSH 완전 차단 (SSM Session Manager 사용)
allowed_ssh_cidrs = []

# 모니터링: 상세 (1분 간격, 필수)
enable_detailed_monitoring = true

# 추가 태그
additional_tags = {
  CostCenter = "production"
  OnCall     = "infra-team"
}

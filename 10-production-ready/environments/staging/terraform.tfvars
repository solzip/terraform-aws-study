# ==========================================
# staging 환경 변수 설정
# ==========================================
#
# 스테이징 환경 특성:
#   - 프로덕션과 유사한 구성 (문제 사전 발견)
#   - 중간 수준의 비용
#   - 상세 모니터링 활성화
#   - SSH 제한적 허용

environment  = "staging"
project_name = "tf-study"
aws_region   = "ap-northeast-2"

# 네트워크: staging 전용 대역 (10.2.x.x)
vpc_cidr            = "10.2.0.0/16"
public_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24"]
availability_zones  = ["ap-northeast-2a", "ap-northeast-2c"]

# EC2: 중간 사양, 2대 (고가용성 테스트)
instance_type  = "t2.small"
instance_count = 2

# 보안: SSH 차단
allowed_ssh_cidrs = []

# 모니터링: 상세 (1분 간격)
enable_detailed_monitoring = true

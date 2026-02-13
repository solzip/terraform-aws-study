# ==========================================
# modules/ec2/main.tf - EC2 컴퓨팅 모듈
# ==========================================
#
# 이 모듈의 역할:
#   EC2 인스턴스를 생성합니다.
#   환경별로 인스턴스 수, 사양, 모니터링 수준이 달라집니다.
#
# 프로덕션 EC2 설계 원칙:
#   1. AMI ID는 변수로 받음 (외부에서 최신 AMI 조회)
#   2. 서브넷에 고르게 분배 (가용영역 분산)
#   3. user_data로 초기 설정 자동화
#   4. 태그로 관리 정보 표시

# ==========================================
# EC2 인스턴스
# ==========================================
# count를 사용하여 여러 인스턴스를 생성합니다.
#
# 서브넷 분배 로직:
#   count.index % length(var.subnet_ids)
#   → 인스턴스를 서브넷에 순환 배치 (Round-Robin)
#   → 예: 3개 인스턴스, 2개 서브넷
#     인스턴스 0 → 서브넷 0 (0 % 2 = 0)
#     인스턴스 1 → 서브넷 1 (1 % 2 = 1)
#     인스턴스 2 → 서브넷 0 (2 % 2 = 0)
#   → 가용영역에 고르게 분산되어 장애 대응 가능
resource "aws_instance" "this" {
  count = var.instance_count

  # ------------------------------------------
  # 기본 설정
  # ------------------------------------------
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name

  # ------------------------------------------
  # 모니터링 설정
  # ------------------------------------------
  # monitoring = true: CloudWatch 상세 모니터링 (1분 간격)
  # monitoring = false: 기본 모니터링 (5분 간격)
  # 프로덕션에서는 상세 모니터링을 권장합니다.
  monitoring = var.enable_detailed_monitoring

  # ------------------------------------------
  # 루트 볼륨 설정
  # ------------------------------------------
  # gp3: 최신 범용 SSD (gp2보다 가성비 좋음)
  # encrypted: 볼륨 암호화 (프로덕션 필수)
  root_block_device {
    volume_size = 20    # GB
    volume_type = "gp3" # 최신 범용 SSD
    encrypted   = true  # 볼륨 암호화

    tags = merge(var.common_tags, {
      Name = "${var.name_prefix}-root-vol-${count.index + 1}"
    })
  }

  # ------------------------------------------
  # User Data (초기 설정 스크립트)
  # ------------------------------------------
  # EC2가 처음 시작될 때 자동으로 실행되는 스크립트입니다.
  # 웹 서버 설치, 설정 파일 생성 등을 자동화합니다.
  #
  # base64encode: User Data는 Base64로 인코딩해야 합니다.
  # templatefile: 변수를 포함한 스크립트 파일을 로드합니다.
  user_data = base64encode(templatefile(
    "${path.module}/user_data.sh.tpl",
    {
      environment   = var.environment
      instance_name = "${var.name_prefix}-${count.index + 1}"
    }
  ))

  # ------------------------------------------
  # 태그
  # ------------------------------------------
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ec2-${count.index + 1}"
    # 인스턴스 순번 태그 (관리 편의성)
    Index = count.index + 1
  })

  # ------------------------------------------
  # 라이프사이클 설정
  # ------------------------------------------
  # user_data 변경 시 인스턴스를 재생성하지 않도록 합니다.
  # 프로덕션에서 예기치 않은 재생성은 서비스 중단을 초래합니다.
  lifecycle {
    ignore_changes = [user_data]
  }
}

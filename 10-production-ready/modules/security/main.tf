# ==========================================
# modules/security/main.tf - 보안 모듈
# ==========================================
#
# 이 모듈의 역할:
#   Security Group과 IAM Role/Instance Profile을 생성합니다.
#   프로덕션에서 보안은 "기본적으로 모든 것을 차단하고,
#   필요한 것만 허용"하는 원칙을 따릅니다.
#
# 보안 설계 원칙:
#   1. 최소 권한 원칙 (필요한 것만 허용)
#   2. 인바운드는 명시적 허용, 아웃바운드는 전체 허용
#   3. SSH는 특정 IP에서만 허용 (0.0.0.0/0 절대 금지)
#   4. IAM Role은 필요한 권한만 부여

# ==========================================
# Security Group - 웹 서버용
# ==========================================
# Security Group은 EC2의 방화벽 역할을 합니다.
# 인바운드(들어오는)와 아웃바운드(나가는) 트래픽을 제어합니다.
resource "aws_security_group" "web" {
  name_prefix = "${var.name_prefix}-web-"
  description = "Security group for web servers - ${var.name_prefix}"
  vpc_id      = var.vpc_id

  # ------------------------------------------
  # 인바운드 규칙: HTTP (80)
  # ------------------------------------------
  # 웹 서버이므로 HTTP 트래픽은 전체 허용합니다.
  # 실제 서비스에서는 ALB(로드밸런서)를 앞에 두고
  # EC2에는 ALB의 Security Group에서만 접근을 허용합니다.
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ------------------------------------------
  # 인바운드 규칙: HTTPS (443)
  # ------------------------------------------
  # HTTPS도 허용합니다.
  # 프로덕션에서는 HTTP → HTTPS 리다이렉트를 설정하고
  # 실제 트래픽은 HTTPS만 사용하는 것이 좋습니다.
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ------------------------------------------
  # 인바운드 규칙: SSH (22) - 조건부
  # ------------------------------------------
  # SSH는 allowed_ssh_cidrs가 설정된 경우에만 허용합니다.
  # dynamic 블록: 조건에 따라 규칙을 동적으로 생성/생략
  #
  # for_each에 빈 리스트가 전달되면 규칙이 생성되지 않습니다.
  # 이렇게 하면 "SSH 완전 차단"도 가능합니다.
  dynamic "ingress" {
    for_each = length(var.allowed_ssh_cidrs) > 0 ? [1] : []
    content {
      description = "SSH from allowed CIDRs only"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidrs
    }
  }

  # ------------------------------------------
  # 아웃바운드 규칙: 전체 허용
  # ------------------------------------------
  # 서버에서 외부로 나가는 트래픽은 전체 허용합니다.
  # 패키지 업데이트, API 호출 등에 필요합니다.
  # 보안이 매우 엄격한 환경에서는 이것도 제한할 수 있습니다.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1은 모든 프로토콜을 의미
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ------------------------------------------
  # 라이프사이클 설정
  # ------------------------------------------
  # create_before_destroy: 새 SG를 먼저 만들고 이전 SG를 삭제
  # 이렇게 하면 EC2에 항상 SG가 연결되어 있는 상태를 유지합니다.
  # (무중단 교체)
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-web-sg"
  })
}

# ==========================================
# IAM Role - EC2용
# ==========================================
# IAM Role은 EC2가 다른 AWS 서비스에 접근할 때 사용하는 자격증명입니다.
# Access Key를 EC2에 넣는 대신 Role을 사용하는 것이 보안 모범 사례입니다.
#
# assume_role_policy: "누가 이 Role을 사용할 수 있는가"를 정의
# 여기서는 EC2 서비스만 이 Role을 사용할 수 있습니다.
resource "aws_iam_role" "ec2" {
  name_prefix = "${var.name_prefix}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ec2-role"
  })
}

# ==========================================
# IAM Policy - SSM 접근용
# ==========================================
# AWS Systems Manager (SSM)를 통해 EC2에 접속할 수 있습니다.
# SSH 대신 SSM Session Manager를 사용하면:
#   1. SSH 포트(22)를 열 필요 없음 (보안 향상)
#   2. 접속 기록이 자동으로 남음 (감사)
#   3. IAM으로 접근 제어 가능
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ==========================================
# IAM Instance Profile
# ==========================================
# Instance Profile은 IAM Role을 EC2에 연결하는 "어댑터"입니다.
# EC2는 직접 IAM Role을 사용할 수 없고,
# Instance Profile을 통해 간접적으로 사용합니다.
resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.name_prefix}-ec2-"
  role        = aws_iam_role.ec2.name

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ec2-profile"
  })
}

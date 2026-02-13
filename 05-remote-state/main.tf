# ==========================================
# main.tf - 실제 인프라 리소스 정의
# ==========================================
#
# 이 파일은 S3 원격 Backend를 사용하여 State를 관리하는
# 실제 인프라 리소스를 정의합니다.
#
# 이전 브랜치(01-basic)와 동일한 리소스를 생성하지만,
# 핵심 차이점은 State가 로컬이 아닌 S3에 저장된다는 것입니다.
#
# State 저장 위치:
#   로컬 (01-basic)  : ./terraform.tfstate
#   원격 (이 브랜치) : s3://버킷이름/05-remote-state/terraform.tfstate

# ==========================================
# Data Sources - 외부 데이터 조회
# ==========================================

# 최신 Amazon Linux 2023 AMI 자동 조회
# 매번 AMI ID를 수동으로 찾을 필요 없이
# 자동으로 최신 버전을 가져옵니다
data "aws_ami" "amazon_linux_2023" {
  most_recent = true       # 가장 최신 AMI 선택
  owners      = ["amazon"] # Amazon 공식 AMI만 검색

  # AMI 이름 패턴으로 필터링
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Amazon Linux 2023, 64비트
  }

  # 가상화 타입 필터
  filter {
    name   = "virtualization-type"
    values = ["hvm"] # Hardware Virtual Machine (현대적 방식)
  }

  # 루트 디바이스 타입 필터
  filter {
    name   = "root-device-type"
    values = ["ebs"] # EBS 기반 (영구 스토리지)
  }
}

# 사용 가능한 가용 영역 조회
# 리전 내에서 실제 사용 가능한 AZ 목록을 가져옵니다
data "aws_availability_zones" "available" {
  state = "available" # 현재 사용 가능한 AZ만
}

# ==========================================
# VPC (Virtual Private Cloud) - 네트워크 격리
# ==========================================
#
# VPC는 AWS에서 논리적으로 격리된 가상 네트워크입니다.
# 모든 AWS 리소스는 VPC 안에 생성됩니다.
#
# CIDR 블록 설명:
# 10.0.0.0/16 = 10.0.0.0 ~ 10.0.255.255 (65,536개 IP)
# 10.0.1.0/24 = 10.0.1.0 ~ 10.0.1.255 (256개 IP)

resource "aws_vpc" "main" {
  # VPC의 IP 주소 범위
  cidr_block = var.vpc_cidr

  # DNS 관련 설정
  # enable_dns_hostnames: EC2 인스턴스에 DNS 이름 부여
  # enable_dns_support: VPC 내부 DNS 조회 활성화
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ==========================================
# Internet Gateway - 인터넷 연결
# ==========================================
#
# VPC가 인터넷과 통신하려면 Internet Gateway가 필요합니다.
# VPC 하나에 IGW 하나만 연결할 수 있습니다.

resource "aws_internet_gateway" "main" {
  # 이 IGW를 연결할 VPC
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ==========================================
# Public Subnet - 인터넷 접근 가능한 서브넷
# ==========================================
#
# Subnet은 VPC 내에서 IP 주소를 더 작은 범위로 나눈 것입니다.
# Public Subnet = 인터넷에서 직접 접근 가능한 서브넷
# (Route Table에서 0.0.0.0/0 → IGW 경로가 있는 서브넷)

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr

  # 가용 영역 지정 - 첫 번째 사용 가능한 AZ 사용
  availability_zone = data.aws_availability_zones.available.names[0]

  # 이 서브넷에서 생성되는 인스턴스에 자동으로 Public IP 할당
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet"
    Type = "Public"
  }
}

# ==========================================
# Route Table - 네트워크 트래픽 경로 지정
# ==========================================
#
# Route Table은 네트워크 트래픽이 어디로 가야 하는지 결정합니다.
# 목적지 0.0.0.0/0 (인터넷) → Internet Gateway로 라우팅

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # 인터넷으로 향하는 모든 트래픽을 IGW로 보냄
  route {
    cidr_block = "0.0.0.0/0"                  # 목적지: 모든 IP (인터넷)
    gateway_id = aws_internet_gateway.main.id # 경유지: Internet Gateway
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Route Table과 Subnet 연결
# 이 연결이 있어야 Subnet의 트래픽이 Route Table의 규칙을 따릅니다
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Security Group - 가상 방화벽
# ==========================================
#
# Security Group은 인스턴스의 인바운드(들어오는)/아웃바운드(나가는)
# 트래픽을 제어하는 가상 방화벽입니다.
#
# 규칙:
# - 인바운드: 기본 전부 차단, 명시적으로 허용해야 함
# - 아웃바운드: 기본 전부 허용

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for web server - HTTP and SSH access"
  vpc_id      = aws_vpc.main.id

  # 인바운드 규칙: HTTP (포트 80) 허용
  # 웹 브라우저에서 접속할 수 있도록 허용
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 모든 IP에서 접근 허용
  }

  # 인바운드 규칙: SSH (포트 22) 허용
  # 서버에 원격 접속하기 위한 포트
  # ⚠️ 프로덕션에서는 특정 IP만 허용하세요!
  ingress {
    description = "SSH from Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 학습용이므로 모든 IP 허용
  }

  # 아웃바운드 규칙: 모든 트래픽 허용
  # 패키지 다운로드, 외부 API 호출 등을 위해 전체 허용
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 = 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"] # 모든 목적지 허용
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }

  # 교체 시 새 SG를 먼저 만들고 기존 것을 삭제
  # (다운타임 최소화)
  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# EC2 Instance - 가상 서버
# ==========================================
#
# EC2는 AWS의 가상 서버 서비스입니다.
# 이 인스턴스의 정보가 State 파일에 기록됩니다.
#
# State에 기록되는 정보 예시:
# - instance_id: "i-0123456789abcdef0"
# - public_ip: "13.125.123.45"
# - private_ip: "10.0.1.100"
# - security_groups: ["sg-0123456789"]
# 등 모든 속성이 State에 저장됩니다.

resource "aws_instance" "web" {
  # AMI: Amazon Machine Image (서버의 기본 이미지)
  # Data Source에서 자동으로 조회한 최신 Amazon Linux 2023 사용
  ami = data.aws_ami.amazon_linux_2023.id

  # 인스턴스 타입: 서버의 CPU/메모리 사양
  # t2.micro: 1 vCPU, 1GB RAM (프리티어 무료)
  instance_type = var.instance_type

  # 배포할 서브넷
  subnet_id = aws_subnet.public.id

  # 적용할 Security Group
  vpc_security_group_ids = [aws_security_group.web.id]

  # 루트 볼륨(디스크) 설정
  root_block_device {
    volume_size           = 8     # 8GB (프리티어: 최대 30GB 무료)
    volume_type           = "gp3" # General Purpose SSD (최신)
    delete_on_termination = true  # 인스턴스 삭제 시 디스크도 삭제
    encrypted             = true  # 디스크 암호화 활성화
  }

  # IMDSv2 (Instance Metadata Service v2) 강제
  # 보안 모범 사례: 토큰 기반 인증 필수
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 강제
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # User Data: 인스턴스 시작 시 자동 실행되는 스크립트
  # Apache 웹 서버를 설치하고 테스트 페이지를 생성합니다
  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log) 2>&1
              echo "=== User Data Started at $(date) ==="

              # 시스템 패키지 업데이트
              yum update -y

              # Apache 웹 서버 설치 및 시작
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              # 테스트 페이지 생성
              cat > /var/www/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                  <meta charset="UTF-8">
                  <title>05-remote-state Demo</title>
                  <style>
                      body { font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px; background: #1b2838; color: #c7d5e0; }
                      h1 { color: #66c0f4; }
                      .badge { display: inline-block; padding: 4px 12px; border-radius: 12px; background: #2a475e; margin: 3px; }
                      .info { background: rgba(102,192,244,0.1); padding: 12px; border-radius: 8px; margin: 8px 0; border-left: 3px solid #66c0f4; }
                      .highlight { color: #66c0f4; font-weight: bold; }
                  </style>
              </head>
              <body>
                  <h1>05-remote-state</h1>
                  <p>State: <span class="badge">S3 Remote Backend</span></p>
                  <div class="info">
                      <span class="highlight">State Storage:</span> AWS S3 (encrypted)
                  </div>
                  <div class="info">
                      <span class="highlight">State Locking:</span> AWS DynamoDB
                  </div>
                  <div class="info">
                      <span class="highlight">Environment:</span> ${var.environment}
                  </div>
                  <p style="opacity:0.6; font-size:13px;">Managed by Terraform | Remote State Enabled</p>
              </body>
              </html>
              HTML

              echo "=== User Data Completed at $(date) ==="
              EOF

  # IGW가 먼저 생성되어야 인터넷에서 패키지 다운로드 가능
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-${var.environment}-web-server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

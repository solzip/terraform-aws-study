# 메인 리소스 정의 파일
# 실제 AWS 인프라 리소스들을 정의

# ==========================================
# Data Sources (외부 데이터 조회)
# ==========================================

# 최신 Amazon Linux 2023 AMI 찾기
# Data Source를 사용하여 동적으로 최신 AMI ID 조회
# 매번 수동으로 AMI ID를 찾을 필요가 없음
data "aws_ami" "amazon_linux_2023" {
  most_recent = true       # 가장 최신 AMI 선택
  owners      = ["amazon"] # Amazon 공식 AMI만 검색

  # AMI 필터링 조건
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Amazon Linux 2023, x86_64 아키텍처
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] # Hardware Virtual Machine
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"] # EBS 기반 루트 디바이스
  }
}

# 현재 사용 가능한 가용 영역 목록 조회
data "aws_availability_zones" "available" {
  state = "available" # 사용 가능한 AZ만 조회
}

# ==========================================
# VPC (Virtual Private Cloud)
# ==========================================

# VPC 생성 - AWS에서 논리적으로 격리된 네트워크 공간
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr # IP 주소 범위 (예: 10.0.0.0/16 = 65,536개 IP)

  # DNS 호스트네임 활성화 - EC2 인스턴스가 DNS 이름을 가질 수 있음
  enable_dns_hostnames = true

  # DNS 지원 활성화 - VPC 내부 DNS 확인 가능
  enable_dns_support = true

  # 리소스에 붙일 태그 (식별 및 관리 용도)
  tags = merge(
    var.additional_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )
}

# ==========================================
# Internet Gateway
# ==========================================

# Internet Gateway 생성
# VPC가 인터넷과 통신할 수 있도록 해주는 게이트웨이
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id # 위에서 생성한 VPC에 연결

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )
}

# ==========================================
# Subnet
# ==========================================

# Public Subnet 생성
# 인터넷에 직접 접근 가능한 서브넷
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr # Subnet의 IP 주소 범위

  # 가용 영역 지정 - 변수로 지정되지 않으면 첫 번째 가용 영역 사용
  availability_zone = var.availability_zone != null ? var.availability_zone : data.aws_availability_zones.available.names[0]

  # Public IP 자동 할당 - 이 서브넷에서 생성되는 인스턴스는 자동으로 Public IP를 받음
  map_public_ip_on_launch = true

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-subnet"
      Type = "Public" # 서브넷 타입 표시
    }
  )
}

# ==========================================
# Route Table
# ==========================================

# Public Route Table 생성
# 네트워크 트래픽의 경로를 결정하는 라우팅 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # 인터넷으로 향하는 트래픽(0.0.0.0/0)은 Internet Gateway로 라우팅
  route {
    cidr_block = "0.0.0.0/0" # 모든 IP (인터넷)
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-rt"
      Type = "Public"
    }
  )
}

# Route Table과 Subnet 연결
# Public Subnet에 Public Route Table을 적용
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Security Group
# ==========================================

# Security Group 생성
# 인스턴스의 인바운드/아웃바운드 트래픽을 제어 (방화벽 역할)
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for web server - allows HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  # 인바운드 규칙 - HTTP 트래픽 허용
  ingress {
    description = "HTTP from Internet"
    from_port   = 80                           # 시작 포트
    to_port     = 80                           # 종료 포트
    protocol    = "tcp"                        # 프로토콜
    cidr_blocks = var.allowed_http_cidr_blocks # 허용할 IP 범위
  }

  # 인바운드 규칙 - SSH 트래픽 허용
  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks # 보안을 위해 특정 IP만 허용 권장
  }

  # 아웃바운드 규칙 - 모든 트래픽 허용
  # 인스턴스에서 외부로 나가는 모든 연결 허용 (패키지 다운로드 등)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1은 모든 프로토콜을 의미
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.project_name}-${var.environment}-web-sg"
    }
  )

  # Security Group은 종종 다른 리소스에서 참조되므로
  # 삭제 전에 새로운 것을 먼저 생성
  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# EC2 Instance
# ==========================================

# EC2 인스턴스 생성
# 실제 가상 서버 인스턴스
resource "aws_instance" "web" {
  # AMI ID - 변수로 지정되었으면 사용, 아니면 최신 Amazon Linux 2023 사용
  ami = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023.id

  instance_type = var.instance_type    # 인스턴스 크기 (t2.micro 등)
  subnet_id     = aws_subnet.public.id # 배포할 서브넷

  # Security Group 연결
  vpc_security_group_ids = [aws_security_group.web.id]

  # 루트 볼륨 설정
  root_block_device {
    volume_size           = var.root_volume_size # 볼륨 크기 (GB)
    volume_type           = "gp3"                # General Purpose SSD (gp3가 gp2보다 성능/가격 우수)
    delete_on_termination = true                 # 인스턴스 삭제 시 볼륨도 함께 삭제
    encrypted             = true                 # 볼륨 암호화 (보안 강화)

    tags = merge(
      var.additional_tags,
      {
        Name = "${var.project_name}-${var.environment}-root-volume"
      }
    )
  }

  # 상세 모니터링 활성화 (선택사항 - 추가 비용 발생)
  monitoring = var.enable_detailed_monitoring

  # EBS 최적화 (선택사항)
  ebs_optimized = var.enable_ebs_optimization

  # 인스턴스 메타데이터 옵션 (보안 강화)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 사용 강제 (보안 권장사항)
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # User Data - 인스턴스 시작 시 자동으로 실행되는 스크립트
  # 웹 서버를 자동으로 설치하고 간단한 페이지 생성
  user_data = <<-EOF
              #!/bin/bash
              # User Data 스크립트 실행 로그
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              echo "=== User Data Script Started at $(date) ==="

              # 시스템 패키지 업데이트
              echo "Updating system packages..."
              yum update -y

              # Apache 웹 서버 설치
              echo "Installing Apache web server..."
              yum install -y httpd

              # Apache 서비스 시작 및 부팅 시 자동 시작 설정
              echo "Starting Apache service..."
              systemctl start httpd
              systemctl enable httpd

              # 간단한 HTML 페이지 생성
              echo "Creating index.html..."
              cat > /var/www/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Terraform Basic - 01-basic</title>
                  <style>
                      body {
                          font-family: Arial, sans-serif;
                          max-width: 800px;
                          margin: 50px auto;
                          padding: 20px;
                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                          color: white;
                      }
                      .container {
                          background: rgba(255, 255, 255, 0.1);
                          padding: 30px;
                          border-radius: 10px;
                          backdrop-filter: blur(10px);
                      }
                      h1 { margin-top: 0; }
                      .info {
                          background: rgba(255, 255, 255, 0.2);
                          padding: 15px;
                          border-radius: 5px;
                          margin: 10px 0;
                      }
                      .success { color: #4ade80; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🎉 Hello from Terraform!</h1>
                      <p class="success">✅ Terraform 인프라 배포 성공!</p>
                      <div class="info">
                          <strong>Instance ID:</strong> $(ec2-metadata --instance-id | cut -d ' ' -f 2)
                      </div>
                      <div class="info">
                          <strong>Availability Zone:</strong> $(ec2-metadata --availability-zone | cut -d ' ' -f 2)
                      </div>
                      <div class="info">
                          <strong>Instance Type:</strong> $(ec2-metadata --instance-type | cut -d ' ' -f 2)
                      </div>
                      <div class="info">
                          <strong>Local IPv4:</strong> $(ec2-metadata --local-ipv4 | cut -d ' ' -f 2)
                      </div>
                      <div class="info">
                          <strong>Public IPv4:</strong> $(ec2-metadata --public-ipv4 | cut -d ' ' -f 2)
                      </div>
                      <p style="margin-top: 30px; font-size: 14px; opacity: 0.8;">
                          Managed by Terraform | Project: ${var.project_name} | Environment: ${var.environment}
                      </p>
                  </div>
              </body>
              </html>
              HTML

              # 권한 설정
              chmod 644 /var/www/html/index.html

              # Apache 설정 확인
              echo "Verifying Apache status..."
              systemctl status httpd

              echo "=== User Data Script Completed at $(date) ==="
              EOF

  # 인스턴스가 완전히 초기화될 때까지 대기
  # User Data 스크립트가 완료될 때까지 시간이 걸릴 수 있음
  depends_on = [
    aws_internet_gateway.main # IGW가 먼저 생성되어야 패키지 다운로드 가능
  ]

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.project_name}-${var.environment}-web-server"
    }
  )

  # 인스턴스 교체 시 중단 시간 최소화
  lifecycle {
    create_before_destroy = true
  }
}
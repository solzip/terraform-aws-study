
# LocalStack용 AWS 리소스 정의
# 01-basic과 유사하지만 LocalStack 환경에 맞게 조정

# ==========================================
# Data Sources
# ==========================================

# LocalStack에서는 실제 AMI가 없으므로 가짜 AMI ID 사용
# 또는 data source를 생략하고 직접 AMI ID 지정
locals {
  # LocalStack용 더미 AMI ID
  # LocalStack은 실제로 AMI를 확인하지 않으므로 임의의 ID 사용 가능
  ami_id = "ami-0c9c942bd7bf113a2"
}

# ==========================================
# VPC
# ==========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ==========================================
# Internet Gateway
# ==========================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ==========================================
# Subnet
# ==========================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  }
}

# ==========================================
# Route Table
# ==========================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Security Group
# ==========================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for web server (LocalStack)"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }
}

# ==========================================
# EC2 Instance
# ==========================================

# 주의: LocalStack에서 EC2 인스턴스는 실제로 실행되지 않습니다
# 메타데이터만 저장되며, User Data 스크립트도 실행되지 않습니다
resource "aws_instance" "web" {
  ami           = local.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.web.id]

  # LocalStack에서는 User Data가 실행되지 않지만
  # 코드 연습을 위해 포함
  user_data = <<-EOF
              #!/bin/bash
              echo "LocalStack 환경 - 이 스크립트는 실제로 실행되지 않습니다"
              yum update -y
              yum install -y httpd
              systemctl start httpd
              echo "<h1>Hello from LocalStack!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-web-server"
  }
}

# ==========================================
# LocalStack 제약사항
# ==========================================
#
# LocalStack 무료 버전의 EC2 제약사항:
#
# 1. 인스턴스가 실제로 실행되지 않음
#    - 메타데이터만 저장됨
#    - SSH 접속 불가능
#    - User Data 스크립트 실행 안 됨
#
# 2. Public IP가 할당되지만 실제로 사용 불가
#    - 네트워크 연결 없음
#    - 실제 웹 서버 실행 안 됨
#
# 3. EBS 볼륨도 메타데이터만
#    - 실제 스토리지 할당 안 됨
#
# 4. 그럼에도 LocalStack의 가치:
#    - Terraform 코드 문법 검증
#    - 리소스 간 의존성 테스트
#    - 비용 없이 무제한 실습
#    - CI/CD 파이프라인 테스트
#
# ==========================================
# 실제 AWS vs LocalStack 비교
# ==========================================
#
# 같은 Terraform 코드로:
#
# LocalStack 사용 시:
# - providers-localstack.tf 사용
# - 비용 없음
# - 실제 서비스 실행 안 됨
#
# 실제 AWS 사용 시:
# - providers-aws.tf 사용
# - 비용 발생 (프리티어 가능)
# - 실제 서비스 실행됨
#
# 학습 방법:
# 1. LocalStack으로 먼저 연습
# 2. 코드에 익숙해지면 실제 AWS로 배포
# 3. 실습 후 terraform destroy로 정리
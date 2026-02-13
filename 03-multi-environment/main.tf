# main.tf
# 멀티 환경을 위한 공통 리소스 정의
# - 동일한 코드로 dev/staging/prod 환경을 관리
# - 환경별 차이는 변수(tfvars)와 조건문으로 처리

# ==========================================
# Local Values (환경별 계산 값)
# ==========================================

locals {
  # 공통 태그 - 모든 리소스에 적용
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # 프로덕션 환경 여부 (조건부 리소스 생성에 활용)
  is_production = var.environment == "prod"

  # 환경별 VPC CIDR 자동 계산
  # prod: 10.0.0.0/16, staging: 10.1.0.0/16, dev: 10.2.0.0/16
  vpc_cidr_map = {
    prod    = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    dev     = "10.2.0.0/16"
  }

  # 환경별 서브넷 수 결정
  # prod: 3개 (Multi-AZ), staging: 2개, dev: 1개
  subnet_count = {
    prod    = 3
    staging = 2
    dev     = 1
  }

  # 실제 사용할 서브넷 수 (가용 영역 수와 설정 중 작은 값)
  actual_subnet_count = min(
    local.subnet_count[var.environment],
    length(data.aws_availability_zones.available.names),
    length(var.public_subnet_cidrs)
  )
}

# ==========================================
# Data Sources
# ==========================================

# 최신 Amazon Linux 2023 AMI 조회
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# 사용 가능한 가용 영역 조회
data "aws_availability_zones" "available" {
  state = "available"
}

# ==========================================
# VPC (환경별 네트워크 격리)
# ==========================================

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# ==========================================
# Internet Gateway
# ==========================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# ==========================================
# Public Subnets (환경별 개수 조정)
# ==========================================

# count를 활용하여 환경별로 다른 수의 서브넷 생성
# dev: 1개, staging: 2개, prod: 3개
resource "aws_subnet" "public" {
  count = local.actual_subnet_count

  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]

  # 각 서브넷을 다른 가용 영역에 분산 배치
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # Public Subnet이므로 자동 Public IP 할당
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
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

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

# 각 Public Subnet에 Route Table 연결
resource "aws_route_table_association" "public" {
  count = local.actual_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Security Group (환경별 규칙 차이)
# ==========================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for ${var.environment} web servers"
  vpc_id      = aws_vpc.main.id

  # HTTP 허용
  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr_blocks
  }

  # SSH 허용 (Prod에서는 제한된 IP만 허용하는 것을 권장)
  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  # 아웃바운드 - 모든 트래픽 허용
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# EC2 Instances (환경별 개수 및 사양)
# ==========================================

# count를 사용하여 환경별 인스턴스 수 조정
# dev: 1대, staging: 2대, prod: 3대
resource "aws_instance" "web" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # 서브넷에 라운드 로빈 방식으로 분산 배치
  subnet_id = aws_subnet.public[count.index % local.actual_subnet_count].id

  vpc_security_group_ids = [aws_security_group.web.id]

  # 루트 볼륨 설정
  root_block_device {
    volume_size           = local.is_production ? 20 : 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # 환경별 모니터링 설정
  monitoring = var.enable_monitoring

  # IMDSv2 강제 (보안 권장사항)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # User Data - 웹 서버 자동 설치
  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log) 2>&1
              echo "=== User Data Started at $(date) ==="

              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                  <meta charset="UTF-8">
                  <title>${var.project_name} - ${var.environment}</title>
                  <style>
                      body { font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px; background: #1a1a2e; color: white; }
                      .env-badge { display: inline-block; padding: 5px 15px; border-radius: 20px; font-weight: bold; }
                      .dev { background: #2ecc71; }
                      .staging { background: #f39c12; }
                      .prod { background: #e74c3c; }
                      .info { background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px; margin: 10px 0; }
                  </style>
              </head>
              <body>
                  <h1>Multi-Environment Demo</h1>
                  <p>Environment: <span class="env-badge ${var.environment}">${var.environment}</span></p>
                  <div class="info"><strong>Instance:</strong> web-${var.environment}-#${count.index + 1}</div>
                  <div class="info"><strong>Type:</strong> ${var.instance_type}</div>
                  <p>Managed by Terraform | Project: ${var.project_name}</p>
              </body>
              </html>
              HTML

              echo "=== User Data Completed at $(date) ==="
              EOF

  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name   = "${var.project_name}-${var.environment}-web-${count.index + 1}"
    Backup = var.enable_backup ? "Required" : "Optional"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# 조건부 리소스 (Prod 환경에서만 생성)
# ==========================================

# Prod 환경에서만 EIP 할당 (고정 IP 필요)
resource "aws_eip" "web" {
  count = local.is_production ? var.instance_count : 0

  instance = aws_instance.web[count.index].id
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# ==========================================
# Module 호출 (web-app 모듈)
# ==========================================

module "web_app" {
  source = "./modules/web-app"

  project_name  = var.project_name
  environment   = var.environment
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.public[0].id
  instance_type = var.instance_type
  is_production = local.is_production
  common_tags   = local.common_tags
  ami_id        = data.aws_ami.amazon_linux_2023.id

  depends_on = [aws_internet_gateway.main]
}

# ==========================================
# main.tf - CI/CD로 배포할 예시 인프라
# ==========================================
#
# 이 파일은 GitHub Actions 워크플로우가
# 실제로 배포할 간단한 인프라를 정의합니다.
#
# CI/CD의 핵심은 "인프라 코드"가 아니라
# "자동화 파이프라인"이므로, 인프라는 간단하게 구성합니다.

# ==========================================
# Local Values
# ==========================================

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ==========================================
# Data Sources
# ==========================================

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
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ==========================================
# VPC
# ==========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  })
}

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

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Security Group
# ==========================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Web server SG deployed via CI/CD"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
  })
}

# ==========================================
# EC2 Instance
# ==========================================

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.web.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                  <meta charset="UTF-8">
                  <title>09-ci-cd</title>
                  <style>
                      body { font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px; background: #0d1117; color: #c9d1d9; }
                      h1 { color: #58a6ff; }
                      .ok { color: #3fb950; }
                      .badge { display: inline-block; padding: 3px 10px; border-radius: 10px; margin: 2px; font-size: 12px; }
                      .ga { background: #238636; color: white; }
                      .tf { background: #7b42bc; color: white; }
                      .info { background: #161b22; padding: 12px; border-radius: 8px; margin: 8px 0; border: 1px solid #30363d; }
                  </style>
              </head>
              <body>
                  <h1>09-ci-cd</h1>
                  <p class="ok">Deployed via GitHub Actions CI/CD Pipeline</p>
                  <div class="info">
                      <span class="badge ga">GitHub Actions</span>
                      <span class="badge tf">Terraform</span>
                  </div>
                  <div class="info">Automated: fmt -> validate -> plan -> apply</div>
                  <div class="info">PR-based workflow with review gates</div>
              </body>
              </html>
              HTML
              EOF

  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cicd-web"
  })
}

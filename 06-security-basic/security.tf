# ==========================================
# security.tf - 보안 리소스 및 모듈 호출
# ==========================================
#
# 이 파일은 보안 관련 모든 리소스를 통합 관리합니다.
# 모듈을 호출하고, VPC/EC2 등 인프라 리소스도 함께 정의합니다.
#
# 보안 구성 요약:
#   1. IAM 모듈 → EC2에게 최소 권한 역할 부여
#   2. KMS 모듈 → 데이터 암호화 키 생성
#   3. Secrets 모듈 → 민감 정보 안전 저장
#   4. Security Group → 네트워크 접근 제어
#   5. EC2 인스턴스 → IAM Role이 연결된 보안 인스턴스

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
}

# 가용 영역 조회
data "aws_availability_zones" "available" {
  state = "available"
}

# ==========================================
# 모듈 호출: IAM
# ==========================================

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
}

# ==========================================
# 모듈 호출: KMS
# ==========================================

module "kms" {
  source = "./modules/kms"

  project_name            = var.project_name
  environment             = var.environment
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = var.enable_key_rotation
  common_tags             = local.common_tags
}

# ==========================================
# 모듈 호출: Secrets Manager
# ==========================================

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.key_arn # KMS 모듈의 키를 사용하여 암호화
  common_tags  = local.common_tags
}

# ==========================================
# VPC - 네트워크 격리
# ==========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  })
}

# Route Table
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
# Security Group - 세밀한 접근 제어
# ==========================================
#
# 이전 브랜치와 다른 점:
# - 각 규칙에 명확한 설명(description) 추가
# - 최소 필요 포트만 개방
# - 아웃바운드도 필요한 것만 허용하는 것이 이상적
#   (학습 목적으로 아웃바운드는 전체 허용)

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Strictly controlled security group for web server"
  vpc_id      = aws_vpc.main.id

  # HTTP (80) - 웹 서비스용
  ingress {
    description = "HTTP - Web service access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (22) - 관리 접근용
  # 프로덕션에서는 반드시 특정 IP만 허용해야 합니다!
  ingress {
    description = "SSH - Admin access (restrict in production!)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  # 아웃바운드 - HTTPS만 허용 (패키지 다운로드, API 호출)
  egress {
    description = "HTTPS outbound - Package downloads, API calls"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 - HTTP (yum 리포지토리 등)
  egress {
    description = "HTTP outbound - Package repositories"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 - DNS
  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
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
# EC2 Instance - IAM Role이 연결된 보안 인스턴스
# ==========================================
#
# 이전 브랜치와 다른 점:
# - iam_instance_profile로 IAM Role 연결
#   → Access Key 없이 AWS 서비스에 접근 가능
# - KMS로 암호화된 루트 볼륨
# - IMDSv2 강제 (보안 모범 사례)

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.web.id]

  # IAM Instance Profile 연결
  # 이것이 이 브랜치의 핵심!
  # EC2가 IAM Role의 권한으로 S3, CloudWatch, Secrets Manager에 접근 가능
  iam_instance_profile = module.iam.ec2_instance_profile_name

  # KMS로 암호화된 루트 볼륨
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = module.kms.key_arn # 고객 관리형 KMS 키로 암호화
  }

  # IMDSv2 강제
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log) 2>&1
              echo "=== Security Basic Demo ==="

              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                  <meta charset="UTF-8">
                  <title>06-security-basic</title>
                  <style>
                      body { font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px; background: #0d1117; color: #c9d1d9; }
                      h1 { color: #58a6ff; }
                      .secure { color: #3fb950; }
                      .badge { display: inline-block; padding: 3px 10px; border-radius: 10px; margin: 2px; font-size: 12px; }
                      .iam { background: #1f6feb; color: white; }
                      .kms { background: #8b5cf6; color: white; }
                      .sm { background: #f97316; color: white; }
                      .info { background: #161b22; padding: 12px; border-radius: 8px; margin: 8px 0; border: 1px solid #30363d; }
                  </style>
              </head>
              <body>
                  <h1>06-security-basic</h1>
                  <p class="secure">All security features enabled</p>
                  <div class="info">
                      <span class="badge iam">IAM Role</span>
                      <span class="badge kms">KMS Encryption</span>
                      <span class="badge sm">Secrets Manager</span>
                  </div>
                  <div class="info">EC2 has IAM Role (no Access Keys needed)</div>
                  <div class="info">EBS encrypted with Customer Managed KMS Key</div>
                  <div class="info">Secrets stored in AWS Secrets Manager</div>
              </body>
              </html>
              HTML
              EOF

  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-secure-web"
  })
}

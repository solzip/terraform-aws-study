# ==========================================
# monitoring.tf - 메인 인프라 + 모듈 호출
# ==========================================
#
# 이 파일은 모니터링 대상 인프라(VPC, EC2)와
# 모니터링 모듈들을 통합 관리합니다.
#
# 모니터링 구성 요약:
#   1. SNS 모듈 → 알림 채널 설정 (이메일, Slack 등)
#   2. Logs 모듈 → 로그 그룹 생성 (애플리케이션, 시스템, 접근, 에러)
#   3. CloudWatch 모듈 → 메트릭, 알람, 대시보드 설정
#   4. CloudTrail 모듈 → API 감사 로깅
#   5. VPC/EC2 → 모니터링 대상 인프라

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
# 모듈 호출: SNS (알림)
# ==========================================
#
# 가장 먼저 SNS를 생성합니다.
# 다른 모듈들이 SNS Topic ARN을 참조하기 때문입니다.

module "sns" {
  source = "./modules/monitoring/sns"

  project_name = var.project_name
  environment  = var.environment
  alarm_email  = var.alarm_email
  common_tags  = local.common_tags
}

# ==========================================
# 모듈 호출: Logs (로그 그룹)
# ==========================================
#
# 로그 그룹을 먼저 생성합니다.
# CloudWatch 모듈의 Metric Filter가 로그 그룹을 참조합니다.

module "logs" {
  source = "./modules/monitoring/logs"

  project_name   = var.project_name
  environment    = var.environment
  retention_days = var.log_retention_days
  common_tags    = local.common_tags
}

# ==========================================
# VPC - 모니터링 대상 네트워크
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
  description = "Web server security group with monitoring"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
# EC2 Instance - 모니터링 대상
# ==========================================
#
# 이 인스턴스의 CPU, 네트워크, 상태를 모니터링합니다.
# 상세 모니터링(1분 간격)을 활성화합니다.

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.web.id]

  # 상세 모니터링 활성화 (1분 간격)
  # 기본 모니터링은 5분 간격이지만,
  # 알람의 정확도를 높이기 위해 1분 간격으로 설정
  monitoring = true

  # IMDSv2 강제
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log) 2>&1
              echo "=== Monitoring Demo ==="

              yum update -y
              yum install -y httpd

              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                  <meta charset="UTF-8">
                  <title>08-monitoring</title>
                  <style>
                      body { font-family: Arial; max-width: 700px; margin: 50px auto; padding: 20px; background: #0d1117; color: #c9d1d9; }
                      h1 { color: #58a6ff; }
                      .ok { color: #3fb950; }
                      .badge { display: inline-block; padding: 3px 10px; border-radius: 10px; margin: 2px; font-size: 12px; }
                      .cw { background: #f97316; color: white; }
                      .sns { background: #ef4444; color: white; }
                      .ct { background: #8b5cf6; color: white; }
                      .log { background: #10b981; color: white; }
                      .info { background: #161b22; padding: 12px; border-radius: 8px; margin: 8px 0; border: 1px solid #30363d; }
                  </style>
              </head>
              <body>
                  <h1>08-monitoring</h1>
                  <p class="ok">All monitoring features active</p>
                  <div class="info">
                      <span class="badge cw">CloudWatch</span>
                      <span class="badge sns">SNS Alerts</span>
                      <span class="badge ct">CloudTrail</span>
                      <span class="badge log">Centralized Logs</span>
                  </div>
                  <div class="info">CPU, Network, StatusCheck alarms configured</div>
                  <div class="info">CloudWatch Dashboard for real-time monitoring</div>
                  <div class="info">CloudTrail auditing all API calls</div>
                  <div class="info">Root login detection enabled</div>
              </body>
              </html>
              HTML
              EOF

  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-monitored-web"
  })
}

# ==========================================
# 모듈 호출: CloudWatch (메트릭, 알람, 대시보드)
# ==========================================
#
# EC2 인스턴스가 생성된 후에 호출합니다.
# 인스턴스 ID를 알아야 메트릭을 필터링할 수 있기 때문입니다.

module "cloudwatch" {
  source = "./modules/monitoring/cloudwatch"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  instance_id          = aws_instance.web.id
  cpu_threshold        = var.cpu_alarm_threshold
  monitoring_topic_arn = module.sns.monitoring_topic_arn
  critical_topic_arn   = module.sns.critical_topic_arn
  app_log_group_name   = module.logs.app_log_group_name
  enable_dashboard     = var.enable_dashboard
  common_tags          = local.common_tags
}

# ==========================================
# 모듈 호출: CloudTrail (감사 로깅)
# ==========================================

module "cloudtrail" {
  source = "./modules/monitoring/cloudtrail"

  count = var.enable_cloudtrail ? 1 : 0

  project_name       = var.project_name
  environment        = var.environment
  retention_days     = var.log_retention_days
  critical_topic_arn = module.sns.critical_topic_arn
  common_tags        = local.common_tags
}

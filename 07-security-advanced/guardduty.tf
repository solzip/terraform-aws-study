# ==========================================
# guardduty.tf - AWS GuardDuty 위협 탐지
# ==========================================
#
# GuardDuty란?
#   AWS의 지능형 위협 탐지 서비스입니다.
#   머신러닝과 이상 탐지 기술을 사용하여
#   AWS 환경에서 악의적 활동을 자동으로 감지합니다.
#
# GuardDuty가 분석하는 데이터:
#   1. VPC Flow Logs - 네트워크 트래픽 이상 감지
#   2. DNS Logs - 악성 도메인 통신 감지
#   3. CloudTrail Events - 비정상 API 호출 감지
#   4. S3 Data Events - S3 데이터 접근 이상 감지
#
# GuardDuty가 탐지하는 위협 유형:
#   - 암호화폐 채굴 (CryptoCurrency)
#   - 무차별 대입 공격 (Brute Force)
#   - 데이터 유출 (Exfiltration)
#   - 권한 상승 (Privilege Escalation)
#   - 비인가 접근 (Unauthorized Access)
#   - 악성 IP 통신 (Malicious Communication)
#
# 비용:
#   - 30일 무료 평가판 제공
#   - 이후 분석된 이벤트 수에 따라 과금
#   - CloudTrail Events: 100만 이벤트당 $4.00
#   - VPC Flow Logs: GB당 $1.00~$1.50
#   - 학습용으로는 무료 평가 기간 내 충분

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

# 현재 AWS 계정 정보
data "aws_caller_identity" "current" {}

# 현재 AWS 리전
data "aws_region" "current" {}

# ==========================================
# GuardDuty Detector (탐지기) 활성화
# ==========================================
#
# Detector는 GuardDuty의 핵심 리소스입니다.
# Detector를 생성하면 GuardDuty가 활성화되어
# 위협 탐지를 시작합니다.
#
# 리전별로 하나의 Detector만 존재할 수 있습니다.

resource "aws_guardduty_detector" "main" {
  # enable_guardduty 변수가 true일 때만 생성
  count = var.enable_guardduty ? 1 : 0

  # GuardDuty 활성화
  enable = true

  # 탐지 결과(Findings)의 게시 빈도
  # FIFTEEN_MINUTES: 15분마다 (가장 빈번)
  # ONE_HOUR: 1시간마다
  # SIX_HOURS: 6시간마다 (기본값)
  #
  # 학습용으로는 SIX_HOURS면 충분합니다.
  # 프로덕션에서는 FIFTEEN_MINUTES를 권장합니다.
  finding_publishing_frequency = "SIX_HOURS"

  # 데이터 소스 설정
  # GuardDuty가 분석할 AWS 서비스 로그를 설정합니다
  datasources {
    # S3 데이터 이벤트 분석
    # S3 버킷에 대한 비정상적인 접근 패턴을 감지
    s3_logs {
      enable = true
    }

    # Kubernetes 감사 로그 (EKS 사용 시)
    # EKS를 사용하지 않으므로 비활성화
    kubernetes {
      audit_logs {
        enable = false
      }
    }

    # 맬웨어 보호
    # EBS 볼륨에서 맬웨어를 스캔
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-guardduty"
  })
}

# ==========================================
# SNS Topic - GuardDuty 알림용
# ==========================================
#
# GuardDuty가 위협을 탐지하면 SNS를 통해 알림을 보냅니다.
# SNS Topic에 이메일, Slack 등을 구독하면 실시간 알림을 받을 수 있습니다.
#
# SNS (Simple Notification Service)란?
#   메시지를 발행(publish)하면 구독자(subscriber)들에게
#   자동으로 전달하는 서비스입니다.
#   구독 방식: 이메일, SMS, HTTP, Lambda, SQS 등

resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-${var.environment}-security-alerts"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-security-alerts"
  })
}

# ==========================================
# CloudWatch Event Rule - GuardDuty Findings
# ==========================================
#
# GuardDuty가 위협을 탐지하면 EventBridge(CloudWatch Events)에
# 이벤트가 발생합니다. 이 이벤트를 SNS Topic으로 전달합니다.
#
# 이벤트 흐름:
#   GuardDuty Finding → EventBridge Rule → SNS Topic → 이메일/Slack

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  count = var.enable_guardduty ? 1 : 0

  name        = "${var.project_name}-${var.environment}-guardduty-findings"
  description = "GuardDuty 위협 탐지 결과를 캡처하여 알림 전송"

  # 이벤트 패턴: GuardDuty에서 발생하는 모든 Finding
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })

  tags = local.common_tags
}

# EventBridge Rule의 대상: SNS Topic
resource "aws_cloudwatch_event_target" "guardduty_sns" {
  count = var.enable_guardduty ? 1 : 0

  rule      = aws_cloudwatch_event_rule.guardduty_findings[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}

# SNS Topic이 EventBridge로부터 메시지를 받을 수 있도록 정책 설정
resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# ==========================================
# VPC - 네트워크 인프라
# ==========================================
#
# 보안 기능을 테스트할 VPC 환경을 구성합니다.
# 06-security-basic과 동일한 기본 구조입니다.

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
  description = "Advanced security group with strict rules"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    description = "HTTP - Web service"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH - 제한된 접근
  ingress {
    description = "SSH - Restricted admin access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  # 아웃바운드 - HTTPS만
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound - Package repos"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS"
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
# 모듈 호출: KMS
# ==========================================

module "kms" {
  source = "./modules/security/kms"

  project_name            = var.project_name
  environment             = var.environment
  deletion_window_in_days = var.kms_deletion_window_days
  common_tags             = local.common_tags
}

# ==========================================
# 모듈 호출: IAM Policies
# ==========================================

module "iam_policies" {
  source = "./modules/security/iam-policies"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  common_tags  = local.common_tags
}

# ==========================================
# 모듈 호출: Secrets Manager
# ==========================================

module "secrets_manager" {
  source = "./modules/security/secrets-manager"

  project_name    = var.project_name
  environment     = var.environment
  kms_key_arn     = module.kms.secrets_key_arn
  enable_rotation = false # 학습용으로는 기본 비활성화 (Lambda 비용 절감)
  rotation_days   = var.secret_rotation_days
  common_tags     = local.common_tags
}

# ==========================================
# 모듈 호출: VPC Flow Logs
# ==========================================

module "vpc_flow_logs" {
  source = "./modules/security/vpc-flow-logs"

  # enable_vpc_flow_logs가 true일 때만 모듈 내 리소스 생성
  count = var.enable_vpc_flow_logs ? 1 : 0

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = aws_vpc.main.id
  retention_days      = var.flow_log_retention_days
  alarm_sns_topic_arn = aws_sns_topic.security_alerts.arn
  common_tags         = local.common_tags
}

# ==========================================
# EC2 Instance - 보안 강화 인스턴스
# ==========================================

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.web.id]

  # IAM Instance Profile (최소 권한 + Permission Boundary 적용)
  iam_instance_profile = module.iam_policies.ec2_instance_profile_name

  # KMS로 암호화된 루트 볼륨
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = module.kms.main_key_arn
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
              echo "=== Security Advanced Demo ==="

              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html lang="ko">
              <head>
                  <meta charset="UTF-8">
                  <title>07-security-advanced</title>
                  <style>
                      body { font-family: Arial; max-width: 700px; margin: 50px auto; padding: 20px; background: #0d1117; color: #c9d1d9; }
                      h1 { color: #58a6ff; }
                      .secure { color: #3fb950; }
                      .badge { display: inline-block; padding: 3px 10px; border-radius: 10px; margin: 2px; font-size: 12px; }
                      .iam { background: #1f6feb; color: white; }
                      .kms { background: #8b5cf6; color: white; }
                      .sm { background: #f97316; color: white; }
                      .gd { background: #ef4444; color: white; }
                      .fl { background: #10b981; color: white; }
                      .config { background: #6366f1; color: white; }
                      .info { background: #161b22; padding: 12px; border-radius: 8px; margin: 8px 0; border: 1px solid #30363d; }
                  </style>
              </head>
              <body>
                  <h1>07-security-advanced</h1>
                  <p class="secure">All advanced security features enabled</p>
                  <div class="info">
                      <span class="badge iam">IAM ABAC</span>
                      <span class="badge kms">KMS Rotation</span>
                      <span class="badge sm">Secret Rotation</span>
                      <span class="badge gd">GuardDuty</span>
                      <span class="badge fl">Flow Logs</span>
                      <span class="badge config">Config Rules</span>
                  </div>
                  <div class="info">Permission Boundary limits maximum permissions</div>
                  <div class="info">Tag-based access control (ABAC) enabled</div>
                  <div class="info">VPC Flow Logs monitoring all traffic</div>
                  <div class="info">GuardDuty detecting threats automatically</div>
              </body>
              </html>
              HTML
              EOF

  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-secure-web-adv"
  })
}

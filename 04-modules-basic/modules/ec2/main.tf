# modules/ec2/main.tf
# EC2 모듈 - EC2 인스턴스를 캡슐화
#
# 이 모듈이 생성하는 리소스:
# - EC2 Instance (Amazon Linux 2023 기본)

# ==========================================
# Data Source - 최신 AMI 자동 조회
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

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ==========================================
# EC2 Instance
# ==========================================

resource "aws_instance" "this" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.security_group_ids

  # 루트 볼륨
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = merge(var.additional_tags, {
      Name = "${var.project_name}-${var.environment}-root-volume"
    })
  }

  # 상세 모니터링
  monitoring = var.enable_monitoring

  # IMDSv2 보안 설정
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # User Data (선택사항)
  user_data = var.user_data

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-${var.environment}-web-server"
  })

  lifecycle {
    create_before_destroy = true
  }
}

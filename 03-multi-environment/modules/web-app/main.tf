# modules/web-app/main.tf
# 재사용 가능한 웹 앱 모듈
# - Security Group + EC2 Instance를 하나의 모듈로 캡슐화
# - 환경별로 동일한 모듈을 호출하되 변수만 변경

# ==========================================
# Security Group (모듈 전용)
# ==========================================

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for ${var.environment} app module"
  vpc_id      = var.vpc_id

  # HTTP 허용 (포트 8080)
  ingress {
    description = "App port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 모든 트래픽 허용
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# EC2 Instance (모듈로 관리되는 앱 서버)
# ==========================================

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.app.id]

  root_block_device {
    volume_size           = var.is_production ? 20 : 8
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  monitoring = var.is_production

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "App module instance for ${var.environment}" > /tmp/app-info.txt
              EOF

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-app"
    Type = "AppModule"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# modules/security-group/main.tf
# Security Group 모듈 - 방화벽 규칙을 캡슐화
#
# 이 모듈이 생성하는 리소스:
# - Security Group (HTTP + SSH 인바운드, 전체 아웃바운드)

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for ${var.environment} web server"
  vpc_id      = var.vpc_id

  # HTTP 인바운드
  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr_blocks
  }

  # SSH 인바운드
  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  # 모든 아웃바운드 허용
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# main.tf
# 루트 모듈 - 각 하위 모듈을 호출하고 조합
#
# 모듈 호출 순서:
# 1. VPC 모듈 → 네트워크 인프라 생성
# 2. Security Group 모듈 → VPC ID를 받아 방화벽 규칙 생성
# 3. EC2 모듈 → Subnet ID와 SG ID를 받아 인스턴스 생성

# ==========================================
# 1. VPC 모듈 - 네트워크 인프라
# ==========================================

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
}

# ==========================================
# 2. Security Group 모듈 - 방화벽 규칙
# ==========================================

# VPC 모듈의 출력(vpc_id)을 SG 모듈의 입력으로 전달
module "security_group" {
  source = "./modules/security-group"

  project_name             = var.project_name
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id # ← 모듈 간 데이터 전달
  allowed_ssh_cidr_blocks  = var.allowed_ssh_cidr_blocks
  allowed_http_cidr_blocks = var.allowed_http_cidr_blocks
}

# ==========================================
# 3. EC2 모듈 - 웹 서버 인스턴스
# ==========================================

# VPC 모듈과 SG 모듈의 출력을 EC2 모듈의 입력으로 전달
module "ec2" {
  source = "./modules/ec2"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_id               # ← VPC 모듈 출력
  security_group_ids = [module.security_group.security_group_id] # ← SG 모듈 출력

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
                      body { font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px; background: #0f3460; color: white; }
                      .module-badge { display: inline-block; padding: 4px 12px; border-radius: 15px; margin: 3px; font-size: 13px; }
                      .vpc { background: #e94560; }
                      .sg { background: #533483; }
                      .ec2 { background: #16213e; border: 1px solid #e94560; }
                      .info { background: rgba(255,255,255,0.1); padding: 12px; border-radius: 8px; margin: 8px 0; }
                  </style>
              </head>
              <body>
                  <h1>04-modules-basic</h1>
                  <p>Modular Infrastructure Demo</p>
                  <div class="info">
                      <strong>Modules Used:</strong><br>
                      <span class="module-badge vpc">VPC Module</span>
                      <span class="module-badge sg">Security Group Module</span>
                      <span class="module-badge ec2">EC2 Module</span>
                  </div>
                  <div class="info"><strong>Environment:</strong> ${var.environment}</div>
                  <div class="info"><strong>Instance Type:</strong> ${var.instance_type}</div>
                  <p style="opacity:0.7; font-size:13px;">Managed by Terraform Modules</p>
              </body>
              </html>
              HTML

              echo "=== User Data Completed at $(date) ==="
              EOF

  # IGW가 먼저 생성되어야 패키지 다운로드 가능
  depends_on = [module.vpc]
}

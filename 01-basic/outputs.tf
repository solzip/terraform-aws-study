# 출력 값 정의 파일
# Terraform 실행 후 중요한 정보를 출력하여 사용자에게 제공

# ==========================================
# VPC 관련 출력
# ==========================================

# VPC ID 출력
output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = aws_vpc.main.id
}

# VPC CIDR 블록 출력
output "vpc_cidr" {
  description = "VPC의 CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

# ==========================================
# Subnet 관련 출력
# ==========================================

# Public Subnet ID 출력
output "public_subnet_id" {
  description = "생성된 Public Subnet의 ID"
  value       = aws_subnet.public.id
}

# Public Subnet CIDR 블록 출력
output "public_subnet_cidr" {
  description = "Public Subnet의 CIDR 블록"
  value       = aws_subnet.public.cidr_block
}

# Public Subnet 가용 영역 출력
output "public_subnet_availability_zone" {
  description = "Public Subnet이 위치한 가용 영역"
  value       = aws_subnet.public.availability_zone
}

# ==========================================
# Security Group 관련 출력
# ==========================================

# Security Group ID 출력
output "security_group_id" {
  description = "Web Server Security Group의 ID"
  value       = aws_security_group.web.id
}

# Security Group 이름 출력
output "security_group_name" {
  description = "Web Server Security Group의 이름"
  value       = aws_security_group.web.name
}

# ==========================================
# EC2 Instance 관련 출력
# ==========================================

# EC2 인스턴스 ID 출력
output "instance_id" {
  description = "EC2 인스턴스의 ID"
  value       = aws_instance.web.id
}

# EC2 인스턴스 Public IP 출력
output "instance_public_ip" {
  description = "EC2 인스턴스의 Public IP 주소"
  value       = aws_instance.web.public_ip
}

# EC2 인스턴스 Private IP 출력
output "instance_private_ip" {
  description = "EC2 인스턴스의 Private IP 주소"
  value       = aws_instance.web.private_ip
}

# EC2 인스턴스 Public DNS 출력
output "instance_public_dns" {
  description = "EC2 인스턴스의 Public DNS 이름"
  value       = aws_instance.web.public_dns
}

# EC2 인스턴스 타입 출력
output "instance_type" {
  description = "EC2 인스턴스의 타입"
  value       = aws_instance.web.instance_type
}

# 사용된 AMI ID 출력
output "ami_id" {
  description = "EC2 인스턴스에 사용된 AMI ID"
  value       = aws_instance.web.ami
}

# ==========================================
# 웹 서버 접속 정보
# ==========================================

# 웹 서버 접속 URL 출력 (가장 중요!)
output "web_url" {
  description = "웹 서버 접속 URL (브라우저에서 이 주소로 접속)"
  value       = "http://${aws_instance.web.public_ip}"
}

# SSH 접속 명령어 출력
output "ssh_command" {
  description = "SSH 접속 명령어 (키 파일이 있는 경우 사용)"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_instance.web.public_ip}"
}

# ==========================================
# 추가 메타데이터
# ==========================================

# Internet Gateway ID 출력
output "internet_gateway_id" {
  description = "Internet Gateway의 ID"
  value       = aws_internet_gateway.main.id
}

# Route Table ID 출력
output "route_table_id" {
  description = "Public Route Table의 ID"
  value       = aws_route_table.public.id
}

# 환경 정보 출력
output "environment" {
  description = "배포된 환경 (dev, staging, prod)"
  value       = var.environment
}

# 프로젝트 이름 출력
output "project_name" {
  description = "프로젝트 이름"
  value       = var.project_name
}

# AWS 리전 출력
output "aws_region" {
  description = "리소스가 배포된 AWS 리전"
  value       = var.aws_region
}

# ==========================================
# 요약 정보 (사용자 편의)
# ==========================================

# 배포 완료 메시지
output "deployment_summary" {
  description = "배포 요약 정보"
  value       = <<-EOT

  ╔════════════════════════════════════════════════════════════════════╗
  ║           Terraform 인프라 배포 완료! 🎉                          ║
  ╠════════════════════════════════════════════════════════════════════╣
  ║                                                                    ║
  ║  웹 서버 접속: http://${aws_instance.web.public_ip}              ║
  ║                                                                    ║
  ║  인스턴스 ID:  ${aws_instance.web.id}                             ║
  ║  VPC ID:       ${aws_vpc.main.id}                                 ║
  ║  리전:         ${var.aws_region}                                  ║
  ║  환경:         ${var.environment}                                 ║
  ║                                                                    ║
  ║  💡 팁: 웹 서버가 완전히 시작되려면 2-3분 정도 걸립니다.          ║
  ║  💡 접속이 안 되면 잠시 후 다시 시도하세요.                       ║
  ║                                                                    ║
  ║  🧹 리소스 정리: terraform destroy                                ║
  ║                                                                    ║
  ╚════════════════════════════════════════════════════════════════════╝

  EOT
}

# ==========================================
# 주의사항
# ==========================================

# 이 출력값들은 다음과 같이 사용할 수 있습니다:
#
# 1. 터미널에서 확인:
#    $ terraform output
#    $ terraform output web_url
#
# 2. 스크립트에서 사용:
#    $ WEB_URL=$(terraform output -raw web_url)
#    $ curl $WEB_URL
#
# 3. JSON 형식으로 출력:
#    $ terraform output -json
#
# 4. 다른 Terraform 프로젝트에서 참조:
#    data "terraform_remote_state" "basic" {
#      backend = "local"
#      config = {
#        path = "../01-basic/terraform.tfstate"
#      }
#    }
#
#    # 사용:
#    vpc_id = data.terraform_remote_state.basic.outputs.vpc_id
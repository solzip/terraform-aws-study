# ==========================================
# outputs.tf - 출력 값 정의
# ==========================================
#
# Terraform 실행 후 사용자에게 보여줄 중요한 정보를 정의합니다.
#
# 출력 값 사용 방법:
#   터미널: terraform output
#   특정 값: terraform output web_url
#   JSON:   terraform output -json
#   스크립트: WEB_URL=$(terraform output -raw web_url)
#
# 출력 값은 State 파일에도 저장되므로,
# 다른 Terraform 프로젝트에서 terraform_remote_state로 참조할 수 있습니다.

# ==========================================
# VPC 관련 출력
# ==========================================

output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = aws_vpc.main.id
}

# ==========================================
# EC2 관련 출력
# ==========================================

output "instance_id" {
  description = "EC2 인스턴스의 ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "EC2 인스턴스의 Public IP 주소"
  value       = aws_instance.web.public_ip
}

# ==========================================
# 접속 정보
# ==========================================

output "web_url" {
  description = "웹 서버 접속 URL"
  value       = "http://${aws_instance.web.public_ip}"
}

output "ssh_command" {
  description = "SSH 접속 명령어"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_instance.web.public_ip}"
}

# ==========================================
# State 관련 정보 (학습용)
# ==========================================

output "state_info" {
  description = "State 관리 정보 요약"
  value       = <<-EOT

  ============================================
   Remote State 정보
  ============================================
   Backend:    S3
   Locking:    DynamoDB
   Encryption: AES-256

   이 인프라의 State는 S3에 원격으로 저장됩니다.
   로컬에 terraform.tfstate 파일이 없는 것을 확인하세요:
     ls -la terraform.tfstate
   → 파일이 없으면 정상! (S3에 저장 중)
  ============================================

  EOT
}

# ==========================================
# modules/ec2/outputs.tf - EC2 모듈 출력값
# ==========================================

output "instance_ids" {
  description = "생성된 EC2 인스턴스 ID 목록"
  value       = aws_instance.this[*].id
}

output "public_ips" {
  description = "EC2 인스턴스의 퍼블릭 IP 목록"
  value       = aws_instance.this[*].public_ip
}

output "private_ips" {
  description = "EC2 인스턴스의 프라이빗 IP 목록"
  value       = aws_instance.this[*].private_ip
}

# modules/ec2/outputs.tf
# EC2 모듈 출력 값

output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "EC2 인스턴스 Public IP"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "EC2 인스턴스 Private IP"
  value       = aws_instance.this.private_ip
}

output "public_dns" {
  description = "EC2 인스턴스 Public DNS"
  value       = aws_instance.this.public_dns
}

output "ami_id" {
  description = "사용된 AMI ID"
  value       = aws_instance.this.ami
}

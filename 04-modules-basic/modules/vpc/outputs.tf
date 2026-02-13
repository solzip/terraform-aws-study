# modules/vpc/outputs.tf
# VPC 모듈 출력 값
# - 다른 모듈에서 참조할 수 있도록 필요한 값을 내보냄

output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC의 CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "Public Subnet의 ID"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "Public Subnet의 CIDR 블록"
  value       = aws_subnet.public.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway의 ID"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "Public Route Table의 ID"
  value       = aws_route_table.public.id
}

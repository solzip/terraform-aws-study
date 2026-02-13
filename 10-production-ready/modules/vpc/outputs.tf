# ==========================================
# modules/vpc/outputs.tf - VPC 모듈 출력값
# ==========================================
#
# 출력값은 이 모듈을 사용하는 쪽에서 참조할 수 있는 값입니다.
# 다른 모듈에서 필요한 정보만 출력합니다.
#
# 예: module.vpc.vpc_id 로 참조

output "vpc_id" {
  description = "생성된 VPC의 ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC의 CIDR 블록"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  # [*]: Splat 표현식 - 리스트의 모든 요소에서 id를 추출
  value = aws_subnet.public[*].id
}

output "internet_gateway_id" {
  description = "인터넷 게이트웨이 ID"
  value       = aws_internet_gateway.this.id
}

# ==========================================
# modules/vpc/main.tf - VPC 네트워크 모듈
# ==========================================
#
# 이 모듈의 역할:
#   완전한 VPC 네트워크 인프라를 생성합니다.
#   VPC, 서브넷, 인터넷 게이트웨이, 라우트 테이블을 포함합니다.
#
# 모듈 설계 원칙:
#   1. 하나의 모듈은 하나의 관심사 (네트워크)
#   2. 변수로 유연하게 설정 가능
#   3. 출력값으로 다른 모듈에 필요한 정보 제공
#   4. 모듈 내부 구현은 외부에서 알 필요 없음 (캡슐화)

# ==========================================
# VPC (Virtual Private Cloud)
# ==========================================
# VPC는 AWS 내에서 논리적으로 격리된 네트워크입니다.
# 모든 리소스는 VPC 안에 생성됩니다.
#
# enable_dns_support: VPC 내부 DNS 해석 활성화
# enable_dns_hostnames: EC2에 퍼블릭 DNS 이름 부여
# 두 옵션 모두 활성화해야 EC2에서 도메인 이름을 사용할 수 있습니다.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# ==========================================
# Internet Gateway
# ==========================================
# 인터넷 게이트웨이는 VPC와 인터넷을 연결하는 관문입니다.
# 퍼블릭 서브넷의 리소스가 인터넷과 통신하려면 반드시 필요합니다.
# VPC당 하나만 생성할 수 있습니다.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# ==========================================
# Public Subnets
# ==========================================
# 서브넷은 VPC 내의 네트워크 세그먼트입니다.
# count를 사용하여 여러 가용영역에 서브넷을 생성합니다.
#
# count = length(var.public_subnet_cidrs)
#   → CIDR 목록의 개수만큼 서브넷 생성
#   → 예: ["10.0.1.0/24", "10.0.2.0/24"] → 2개 생성
#
# map_public_ip_on_launch = true
#   → 이 서브넷에 생성되는 EC2에 자동으로 퍼블릭 IP 부여
#   → 인터넷에서 직접 접근 가능 (퍼블릭 서브넷의 핵심 설정)
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    # 서브넷 유형을 태그로 표시 (관리 편의성)
    Type = "Public"
  })
}

# ==========================================
# Route Table (라우팅 테이블)
# ==========================================
# 라우팅 테이블은 네트워크 트래픽의 경로를 결정합니다.
# "이 목적지로 가려면 어디로 보내라"는 규칙의 모음입니다.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  # 기본 라우트: 모든 트래픽(0.0.0.0/0)을 인터넷 게이트웨이로
  # VPC 내부 트래픽은 자동으로 로컬 라우트가 적용됩니다.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# ==========================================
# Route Table Association (라우팅 테이블 연결)
# ==========================================
# 각 서브넷을 라우팅 테이블에 연결합니다.
# 연결하지 않으면 기본 라우팅 테이블이 적용됩니다.
# 명시적으로 연결하는 것이 관리에 좋습니다.
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

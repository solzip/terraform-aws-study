# modules/vpc/main.tf
# VPC 모듈 - 네트워크 인프라를 캡슐화
#
# 이 모듈이 생성하는 리소스:
# - VPC
# - Internet Gateway
# - Public Subnet
# - Route Table + Association

# ==========================================
# Data Sources
# ==========================================

# 사용 가능한 가용 영역 조회
data "aws_availability_zones" "available" {
  state = "available"
}

# ==========================================
# VPC
# ==========================================

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# ==========================================
# Internet Gateway
# ==========================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# ==========================================
# Public Subnet
# ==========================================

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr

  availability_zone       = var.availability_zone != null ? var.availability_zone : data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet"
    Type = "Public"
  })
}

# ==========================================
# Route Table
# ==========================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.additional_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

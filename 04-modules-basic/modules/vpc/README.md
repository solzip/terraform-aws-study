# VPC Module

VPC, Internet Gateway, Public Subnet, Route Table을 생성하는 모듈입니다.

## 사용법

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name       = "my-project"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | 프로젝트 이름 | string | - (필수) |
| environment | 환경 구분 | string | - (필수) |
| vpc_cidr | VPC CIDR 블록 | string | 10.0.0.0/16 |
| public_subnet_cidr | Public Subnet CIDR | string | 10.0.1.0/24 |
| availability_zone | 가용 영역 | string | null (자동) |
| additional_tags | 추가 태그 | map(string) | {} |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr | VPC CIDR 블록 |
| public_subnet_id | Public Subnet ID |
| public_subnet_cidr | Public Subnet CIDR |
| internet_gateway_id | IGW ID |
| public_route_table_id | Route Table ID |

# Security Group Module

웹 서버용 Security Group을 생성하는 모듈입니다.
HTTP(80)와 SSH(22) 인바운드 규칙을 설정합니다.

## 사용법

```hcl
module "sg" {
  source = "./modules/security-group"

  project_name = "my-project"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id

  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  allowed_http_cidr_blocks = ["0.0.0.0/0"]
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | 프로젝트 이름 | string | - (필수) |
| environment | 환경 구분 | string | - (필수) |
| vpc_id | VPC ID | string | - (필수) |
| allowed_ssh_cidr_blocks | SSH 허용 CIDR 목록 | list(string) | ["0.0.0.0/0"] |
| allowed_http_cidr_blocks | HTTP 허용 CIDR 목록 | list(string) | ["0.0.0.0/0"] |
| additional_tags | 추가 태그 | map(string) | {} |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | Security Group ID |
| security_group_name | Security Group 이름 |

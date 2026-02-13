# EC2 Module

EC2 인스턴스를 생성하는 모듈입니다.
AMI를 지정하지 않으면 최신 Amazon Linux 2023을 자동으로 사용합니다.

## 사용법

```hcl
module "ec2" {
  source = "./modules/ec2"

  project_name       = "my-project"
  environment        = "dev"
  instance_type      = "t2.micro"
  subnet_id          = module.vpc.public_subnet_id
  security_group_ids = [module.sg.security_group_id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | 프로젝트 이름 | string | - (필수) |
| environment | 환경 구분 | string | - (필수) |
| instance_type | 인스턴스 타입 | string | t2.micro |
| ami_id | AMI ID (null이면 자동) | string | null |
| subnet_id | Subnet ID | string | - (필수) |
| security_group_ids | SG ID 목록 | list(string) | - (필수) |
| root_volume_size | 루트 볼륨 크기(GB) | number | 8 |
| enable_monitoring | 상세 모니터링 | bool | false |
| user_data | User Data 스크립트 | string | null |
| additional_tags | 추가 태그 | map(string) | {} |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 인스턴스 ID |
| public_ip | Public IP 주소 |
| private_ip | Private IP 주소 |
| public_dns | Public DNS |
| ami_id | 사용된 AMI ID |

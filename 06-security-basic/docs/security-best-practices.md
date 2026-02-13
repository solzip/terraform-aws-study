# AWS 보안 모범 사례 (Security Best Practices)

## 1. IAM 최소 권한 원칙

### 규칙
- 필요한 최소한의 권한만 부여
- `*` (와일드카드) 사용 최소화
- 리소스 ARN을 구체적으로 지정

### 나쁜 예
```json
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}
```
이 정책은 **모든 AWS 서비스의 모든 동작**을 허용합니다. 매우 위험!

### 좋은 예
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::my-bucket",
    "arn:aws:s3:::my-bucket/*"
  ]
}
```
**특정 버킷**의 **읽기 동작만** 허용합니다.

## 2. 비밀 정보 관리

### 절대 하지 말 것
```hcl
# 코드에 비밀번호 직접 입력 (절대 금지!)
resource "aws_db_instance" "main" {
  password = "mypassword123"  # 이 코드가 Git에 올라가면 비밀번호 노출!
}

# terraform.tfvars에 비밀번호 저장 후 Git 커밋 (절대 금지!)
db_password = "mypassword123"
```

### 올바른 방법
```hcl
# 방법 1: Secrets Manager에서 가져오기
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "my-project/prod/db-password"
}

resource "aws_db_instance" "main" {
  password = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["password"]
}

# 방법 2: random_password로 자동 생성
resource "random_password" "db" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}
```

## 3. 암호화

### 저장 시 암호화 (Encryption at Rest)
```hcl
# S3 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
  }
}

# EBS 볼륨 암호화
root_block_device {
  encrypted  = true
  kms_key_id = aws_kms_key.main.arn
}
```

### 전송 중 암호화 (Encryption in Transit)
- HTTPS 사용 강제 (ALB에서 HTTP → HTTPS 리다이렉트)
- TLS 1.2 이상만 허용

## 4. Security Group 규칙

### 인바운드 - 최소 포트만 개방
```hcl
# 필요한 포트만 명시적으로 허용
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # HTTPS만 공개
}

ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["203.0.113.0/24"]  # SSH는 사무실 IP만!
}
```

### 아웃바운드 - 필요한 대상만 허용
```hcl
# 이상적인 아웃바운드 (필요한 것만)
egress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # HTTPS만 허용
}
```

## 5. IMDSv2 강제

Instance Metadata Service v2를 강제하면 SSRF 공격을 방지할 수 있습니다.

```hcl
metadata_options {
  http_tokens = "required"  # IMDSv2 강제 (토큰 기반)
}
```

## 6. KMS 키 교체

```hcl
resource "aws_kms_key" "main" {
  enable_key_rotation = true  # 1년마다 자동 키 교체
}
```

## 7. 체크리스트

- [ ] IAM Role에 최소 권한만 부여했는가?
- [ ] 비밀번호가 코드나 Git에 노출되지 않았는가?
- [ ] 모든 저장 데이터가 암호화되었는가?
- [ ] Security Group이 최소 포트만 허용하는가?
- [ ] IMDSv2가 강제되었는가?
- [ ] KMS 키 교체가 활성화되었는가?
- [ ] S3 버킷의 퍼블릭 접근이 차단되었는가?

# 06-security-basic - 보안 기초

> 🟡 **난이도**: 중급 | **학습 시간**: 4시간

[← 메인 README로 돌아가기](https://github.com/solzip/terraform-aws-study) | [← 이전: 05-remote-state](https://github.com/solzip/terraform-aws-study/tree/05-remote-state)

## 📚 학습 목표

- ✅ IAM Role 및 Policy 생성 (최소 권한 원칙)
- ✅ IAM Instance Profile로 EC2에 역할 부여
- ✅ AWS KMS 암호화 키 생성 및 관리
- ✅ AWS Secrets Manager로 민감 정보 관리
- ✅ Security Group 세밀한 제어
- ✅ 보안 모범 사례 적용

## 🏗️ 아키텍처

```
┌────────────────────────────────────────────────────────────┐
│                      AWS Cloud                             │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │  IAM Role        │    │  KMS Key         │               │
│  │  - EC2 역할      │    │  - 데이터 암호화 │               │
│  │  - S3 읽기 권한  │    │  - 자동 키 교체  │               │
│  │  - CloudWatch    │    └────────┬────────┘               │
│  └────────┬────────┘              │                         │
│           │                       │ 암호화                  │
│           │ 역할 부여             │                         │
│           ▼                       ▼                         │
│  ┌────────────────┐    ┌─────────────────┐                 │
│  │  EC2 Instance   │    │ Secrets Manager  │                │
│  │  (Instance      │    │  - DB 비밀번호   │                │
│  │   Profile)      │    │  - API 키        │                │
│  └────────────────┘    └─────────────────┘                 │
│                                                             │
│  ┌─────────────────┐                                       │
│  │  Security Group  │                                      │
│  │  - 최소 권한     │                                      │
│  │  - 포트별 제어   │                                      │
│  └─────────────────┘                                       │
└────────────────────────────────────────────────────────────┘
```

## 📁 프로젝트 구조

```
06-security-basic/
├── README.md                         # 현재 문서
├── security.tf                       # 보안 리소스 + 모듈 호출
├── variables.tf                      # 변수 정의
├── outputs.tf                        # 출력 값
├── versions.tf                       # Terraform/Provider 버전
├── modules/
│   ├── iam/                          # IAM 모듈
│   │   ├── roles.tf                  # IAM Role + Instance Profile
│   │   ├── policies.tf               # IAM Policy 정의
│   │   └── outputs.tf                # Role ARN, Profile 이름 출력
│   ├── kms/                          # KMS 모듈
│   │   ├── main.tf                   # KMS Key 생성
│   │   └── outputs.tf                # Key ARN, ID 출력
│   └── secrets/                      # Secrets Manager 모듈
│       ├── main.tf                   # Secret 생성
│       └── outputs.tf                # Secret ARN 출력
└── docs/
    └── security-best-practices.md    # 보안 모범 사례 문서
```

## 🚀 실습 가이드

```bash
git checkout 06-security-basic
cd 06-security-basic   # 실습 코드는 브랜치와 같은 이름의 디렉토리 안에 있습니다

terraform init
terraform plan      # 생성될 보안 리소스 확인
terraform apply

# 리소스 정리
terraform destroy
```

> 이 브랜치의 진입점은 `main.tf`가 아니라 **`security.tf`** 입니다.
> Terraform은 디렉토리 안의 모든 `.tf` 파일을 함께 읽으므로 파일명은 자유이며,
> 여기서는 파일 이름만 봐도 역할을 알 수 있도록 `security.tf`로 두었습니다.

## 💡 핵심 학습 포인트

### 1. IAM 최소 권한 원칙

```hcl
# 나쁜 예 - 모든 권한 부여 (절대 금지!)
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}

# 좋은 예 - 필요한 권한만 부여
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

### 2. KMS 암호화

```hcl
resource "aws_kms_key" "main" {
  description             = "데이터 암호화 키"
  deletion_window_in_days = 7       # 삭제 대기 기간
  enable_key_rotation     = true    # 자동 키 교체 (1년)
}
```

### 3. Secrets Manager

```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name = "db-password"
  kms_key_id = aws_kms_key.main.arn  # KMS로 암호화
}
```

## ✅ 학습 체크리스트

- [ ] IAM Role과 Policy의 차이 이해
- [ ] Instance Profile의 역할 이해
- [ ] KMS 키 생성 및 키 교체 설정
- [ ] Secrets Manager로 비밀 저장
- [ ] 최소 권한 원칙 적용
- [ ] 리소스 정리 완료

## 🔄 다음 단계

보안 기초를 마스터했습니다! 🎉

```bash
terraform destroy
git checkout 07-security-advanced
```

[← 이전: 05-remote-state](https://github.com/solzip/terraform-aws-study/tree/05-remote-state) | [다음: 07-security-advanced →](https://github.com/solzip/terraform-aws-study/tree/07-security-advanced)

---

**작성일**: 2025-02-02
**난이도**: 🟡 중급
**학습 시간**: 4시간

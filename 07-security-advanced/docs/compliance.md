# AWS 컴플라이언스 가이드 (Compliance Guide)

## 컴플라이언스란?

법적 규정, 산업 표준, 내부 정책을 준수하는 것을 말합니다.
AWS 환경에서는 보안 표준을 준수하여 데이터를 안전하게 보호해야 합니다.

## 주요 보안 표준

### 1. CIS AWS Foundations Benchmark

CIS (Center for Internet Security)에서 정의한 AWS 보안 표준입니다.

#### Level 1 (기본) - 모든 환경에 권장

| 번호 | 점검 항목 | 이 프로젝트 적용 |
|------|----------|:---:|
| 1.1 | 루트 계정 사용 제한 | - |
| 1.2 | MFA 활성화 | Config Rule |
| 1.4 | Access Key 비사용 | IAM Role 사용 |
| 1.5 | IAM 비밀번호 정책 | - |
| 1.10 | MFA 조건부 정책 | - |
| 2.1 | CloudTrail 활성화 | - |
| 2.3 | CloudTrail 로그 암호화 | KMS |
| 2.6 | S3 액세스 로깅 | - |
| 3.1 | CloudWatch 로그 알림 | VPC Flow Logs |
| 4.1 | Security Group 제한 | Config Rule |
| 4.3 | VPC Flow Logs 활성화 | VPC Flow Logs 모듈 |

#### Level 2 (심화) - 높은 보안이 필요한 환경

| 번호 | 점검 항목 | 이 프로젝트 적용 |
|------|----------|:---:|
| 1.16 | IAM Policy 최소 권한 | Permission Boundary |
| 2.8 | KMS 키 로테이션 | KMS 모듈 |
| 3.3 | Config 활성화 | Config Rules |
| 4.4 | VPC Peering 제한 | - |

### 2. AWS Foundational Security Best Practices (FSBP)

AWS가 권장하는 보안 모범 사례입니다.

| 카테고리 | 점검 항목 | 적용 방법 |
|----------|----------|----------|
| IAM | 루트 MFA | Config Rule |
| IAM | 최소 권한 | ABAC + Boundary |
| EC2 | IMDSv2 강제 | metadata_options |
| EC2 | EBS 암호화 | KMS 키 |
| S3 | 퍼블릭 접근 차단 | Config Rule |
| KMS | 키 로테이션 | enable_key_rotation |

### 3. PCI DSS (Payment Card Industry Data Security Standard)

신용카드 데이터를 처리하는 환경에 필수인 표준입니다.

| 요구사항 | 설명 | AWS 서비스 |
|----------|------|-----------|
| 요구사항 2 | 기본 비밀번호 변경 | Secrets Manager |
| 요구사항 3 | 저장 데이터 보호 | KMS 암호화 |
| 요구사항 4 | 전송 데이터 암호화 | TLS/SSL |
| 요구사항 7 | 접근 제어 | IAM 최소 권한 |
| 요구사항 8 | 인증 관리 | MFA, Secret 로테이션 |
| 요구사항 10 | 모니터링 및 로깅 | GuardDuty, Flow Logs |
| 요구사항 11 | 보안 테스트 | Config Rules |

## 이 프로젝트의 컴플라이언스 매핑

### 적용된 보안 서비스와 표준 매핑

```
┌────────────────────┬────────┬─────────┬──────────┐
│     서비스         │  CIS   │  FSBP   │ PCI DSS  │
├────────────────────┼────────┼─────────┼──────────┤
│ IAM Role/Policy    │ 1.4    │ IAM.1   │ 요구7,8  │
│ Permission Boundary│ 1.16   │ IAM.6   │ 요구7    │
│ ABAC               │ 1.16   │ -       │ 요구7    │
│ KMS Key Rotation   │ 2.8    │ KMS.1   │ 요구3    │
│ Secrets Manager    │ -      │ -       │ 요구2,8  │
│ Secret Rotation    │ -      │ -       │ 요구8    │
│ VPC Flow Logs      │ 4.3    │ EC2.6   │ 요구10   │
│ GuardDuty          │ -      │ -       │ 요구11   │
│ Config Rules       │ 3.3    │ Config  │ 요구11   │
│ Security Hub       │ -      │ -       │ -        │
│ EBS Encryption     │ -      │ EC2.3   │ 요구3    │
│ IMDSv2             │ -      │ EC2.8   │ -        │
└────────────────────┴────────┴─────────┴──────────┘
```

## Security Hub 점수 해석

Security Hub는 각 표준에 대한 점수(%)를 제공합니다:

| 점수 | 상태 | 조치 |
|------|------|------|
| 90-100% | 우수 | 현상 유지, 정기 검토 |
| 70-89% | 양호 | 미준수 항목 개선 계획 수립 |
| 50-69% | 주의 | 즉시 개선 필요 |
| 0-49% | 위험 | 긴급 조치 필요 |

## 컴플라이언스 자동화 팁

### 1. Config Rules로 자동 감지
```hcl
# 비준수 리소스를 자동으로 탐지
resource "aws_config_config_rule" "encrypted_volumes" {
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
}
```

### 2. GuardDuty로 위협 자동 탐지
```hcl
# 위협이 탐지되면 자동으로 SNS 알림
resource "aws_cloudwatch_event_rule" "guardduty" {
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}
```

### 3. Security Hub로 통합 관리
```hcl
# 모든 보안 서비스 결과를 하나의 대시보드에서 확인
resource "aws_securityhub_account" "main" {
  enable_default_standards = true
}
```

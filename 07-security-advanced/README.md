# 07-security-advanced - AWS 보안 심화

## 학습 목표

06-security-basic에서 배운 IAM, KMS, Secrets Manager 기초 위에
**프로덕션 수준의 보안 체계**를 구축하는 방법을 학습합니다.

## 이 브랜치에서 배우는 내용

### 1. Secrets Manager 자동 로테이션
- Lambda 함수를 이용한 비밀번호 자동 교체
- 로테이션 스케줄 설정 (30일/60일/90일)
- 로테이션 Lambda의 IAM 권한 설계

### 2. KMS 키 로테이션 전략
- 자동 키 로테이션 활성화 및 관리
- 키 정책(Key Policy) 세밀한 제어
- 키 별칭(Alias)을 활용한 키 관리 전략

### 3. IAM 최소 권한 원칙 심화
- 조건부 정책 (Condition)
- 태그 기반 접근 제어 (ABAC)
- 서비스 경계 정책 (Permission Boundary)
- 시간 기반 접근 제어

### 4. VPC Flow Logs
- 네트워크 트래픽 로깅
- CloudWatch Logs로 플로우 로그 전송
- 로그 분석을 위한 로그 그룹 설정

### 5. GuardDuty
- AWS 위협 탐지 서비스 활성화
- 악의적 활동 및 비정상 행동 모니터링
- SNS를 통한 알림 설정

### 6. AWS Config Rules
- 리소스 구성 규칙 준수 여부 모니터링
- 사전 정의된 규칙 (Managed Rules) 활용
- 비준수 리소스 자동 탐지

### 7. Security Hub
- 보안 검사 결과 중앙 집중 관리
- AWS 보안 표준 자동 평가
- 통합 보안 대시보드

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                    AWS Account                       │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ GuardDuty│  │ Security │  │  AWS Config      │  │
│  │ (위협탐지)│  │   Hub    │  │  (규칙 준수 감시) │  │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│       │              │                 │             │
│       └──────────────┼─────────────────┘             │
│                      │                               │
│  ┌───────────────────▼───────────────────┐          │
│  │          CloudWatch / SNS             │          │
│  │       (모니터링 & 알림)                │          │
│  └───────────────────────────────────────┘          │
│                                                     │
│  ┌─────────────────────────────────────┐            │
│  │              VPC                     │            │
│  │  ┌─────────┐     ┌──────────────┐  │            │
│  │  │ EC2     │     │ VPC Flow Logs│  │            │
│  │  │ (IAM    │────▶│ → CloudWatch │  │            │
│  │  │  Role)  │     └──────────────┘  │            │
│  │  └────┬────┘                       │            │
│  └───────┼────────────────────────────┘            │
│          │                                          │
│  ┌───────▼────────┐  ┌──────────────┐              │
│  │ Secrets Manager│  │   KMS        │              │
│  │ + 자동 로테이션 │  │ + 키 로테이션 │              │
│  └────────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────┘
```

## 파일 구조

```
07-security-advanced/
├── README.md                              # 현재 파일
├── versions.tf                            # Terraform/Provider 버전
├── variables.tf                           # 입력 변수 정의
├── outputs.tf                             # 출력 값 정의
├── guardduty.tf                           # GuardDuty 위협 탐지
├── config-rules.tf                        # AWS Config Rules
├── security-hub.tf                        # Security Hub 통합
├── modules/
│   └── security/
│       ├── secrets-manager/               # Secrets Manager 모듈
│       │   ├── main.tf                    # Secret 리소스 정의
│       │   ├── rotation.tf                # 자동 로테이션 Lambda
│       │   ├── variables.tf               # 모듈 입력 변수
│       │   └── outputs.tf                 # 모듈 출력 값
│       ├── kms/                           # KMS 모듈
│       │   ├── key-rotation.tf            # KMS 키 + 로테이션
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── iam-policies/                  # IAM 정책 모듈
│       │   ├── least-privilege.tf         # 최소 권한 정책
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── vpc-flow-logs/                 # VPC Flow Logs 모듈
│           ├── main.tf                    # Flow Logs 리소스
│           ├── cloudwatch.tf              # CloudWatch 로그 그룹
│           ├── variables.tf
│           └── outputs.tf
└── docs/
    ├── security-checklist.md              # 보안 점검 체크리스트
    └── compliance.md                      # 컴플라이언스 가이드
```

## 06-security-basic과의 차이점

| 항목 | 06-security-basic | 07-security-advanced |
|------|-------------------|----------------------|
| Secrets Manager | 기본 저장/조회 | **자동 로테이션** |
| KMS | 키 생성 + 암호화 | **키 정책 세밀 제어** |
| IAM | 기본 Role/Policy | **조건부 정책, ABAC** |
| 네트워크 보안 | Security Group | **VPC Flow Logs** |
| 위협 탐지 | 없음 | **GuardDuty** |
| 규정 준수 | 없음 | **AWS Config Rules** |
| 보안 통합 | 없음 | **Security Hub** |

## 비용 주의

> GuardDuty, AWS Config, Security Hub는 사용량 기반 과금됩니다.
> 학습 후 반드시 `terraform destroy`로 리소스를 삭제하세요!

| 서비스 | 예상 비용 (학습용) |
|--------|-------------------|
| GuardDuty | 30일 무료 평가판 |
| AWS Config | Rule 평가당 ~$0.001 |
| Security Hub | 30일 무료 평가판 |
| VPC Flow Logs | 로그 양에 따라 (소량 무료) |

## 시작하기

```bash
git checkout 07-security-advanced
cd 07-security-advanced
terraform init
terraform plan
terraform apply

# 학습 완료 후 반드시 정리!
terraform destroy
```

# 08-monitoring - 모니터링 & 로깅

## 학습 목표

AWS 환경의 **상태를 실시간으로 관찰**하고,
**문제가 발생하면 즉시 알림**을 받을 수 있는 모니터링 시스템을 구축합니다.

## 이 브랜치에서 배우는 내용

### 1. CloudWatch Metrics (메트릭)
- EC2 CPU 사용률, 메모리, 디스크 등 핵심 지표 수집
- 커스텀 메트릭 생성

### 2. CloudWatch Alarms (알람)
- CPU 80% 초과 시 알림
- StatusCheck 실패 시 알림
- 복합 알람 (여러 조건을 AND/OR로 결합)

### 3. CloudWatch Dashboard (대시보드)
- EC2 인스턴스 핵심 지표를 한눈에 보는 대시보드
- 위젯 구성 (그래프, 숫자, 텍스트)

### 4. SNS Notifications (알림)
- 이메일, SMS, Slack 등으로 알림 전송
- 토픽(Topic)과 구독(Subscription) 구조

### 5. CloudWatch Logs (로그)
- 애플리케이션 로그 중앙 수집
- 로그 필터링 및 검색
- 로그 기반 메트릭 생성

### 6. CloudTrail (감사 로깅)
- 모든 AWS API 호출 기록
- 누가 언제 무엇을 했는지 추적
- 보안 감사 및 규정 준수

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                   CloudWatch                         │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Metrics  │  │ Alarms   │  │   Dashboard      │  │
│  │ (지표)   │  │ (알람)   │  │   (대시보드)     │  │
│  └────┬─────┘  └────┬─────┘  └──────────────────┘  │
│       │              │                               │
│  ┌────▼──────────────▼───────────────────┐          │
│  │          SNS Topic                     │          │
│  │    (이메일/Slack 알림 전송)             │          │
│  └───────────────────────────────────────┘          │
│                                                     │
│  ┌──────────────┐  ┌────────────────────┐           │
│  │ CloudWatch   │  │   CloudTrail       │           │
│  │ Logs (로그)  │  │   (API 감사 로그)  │           │
│  └──────────────┘  └────────────────────┘           │
└─────────────────────────────────────────────────────┘
         ▲                    ▲
         │                    │
    ┌────┴────┐          ┌───┴────┐
    │  EC2    │          │ 모든   │
    │ (로그)  │          │ AWS API│
    └─────────┘          └────────┘
```

## 파일 구조

```
08-monitoring/
├── README.md
├── versions.tf
├── variables.tf
├── monitoring.tf                          # 메인 인프라 + 모듈 호출
├── outputs.tf
├── modules/
│   └── monitoring/
│       ├── cloudwatch/
│       │   ├── metrics.tf                 # 메트릭 설정
│       │   ├── alarms.tf                  # 알람 설정
│       │   ├── dashboards.tf              # 대시보드
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── sns/
│       │   ├── notifications.tf           # SNS 토픽 + 구독
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── logs/
│       │   ├── log-groups.tf              # 로그 그룹 + 필터
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── cloudtrail/
│           ├── audit-trail.tf             # CloudTrail 설정
│           ├── variables.tf
│           └── outputs.tf
└── docs/
    ├── alerting-guide.md
    └── log-analysis.md
```

## 비용 안내

| 서비스 | 프리티어 | 초과 시 비용 |
|--------|---------|-------------|
| CloudWatch Metrics | 10 메트릭 무료 | 메트릭당 $0.30/월 |
| CloudWatch Alarms | 10 알람 무료 | 알람당 $0.10/월 |
| CloudWatch Logs | 5GB 수집 무료 | $0.50/GB |
| CloudWatch Dashboard | 3 대시보드 무료 | $3.00/월 |
| SNS | 이메일 무료 | SMS는 건당 과금 |
| CloudTrail | 관리 이벤트 무료 | 데이터 이벤트 유료 |

## 시작하기

```bash
git checkout 08-monitoring
cd 08-monitoring
terraform init
terraform plan
terraform apply

# 학습 완료 후
terraform destroy
```

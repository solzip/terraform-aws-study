# 08-monitoring - 모니터링 & 로깅

> 🔴 **난이도**: 고급 | **학습 시간**: 5시간

[← 메인 README](https://github.com/solzip/terraform-aws-study) | [← 이전: 07-security-advanced](https://github.com/solzip/terraform-aws-study/tree/07-security-advanced) | [다음: 09-ci-cd →](https://github.com/solzip/terraform-aws-study/tree/09-ci-cd)

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
│       │   ├── log-groups.tf              # 로그 그룹 4종 (app/system/access/error)
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

# 생성된 로그 그룹 확인
terraform output log_groups

# 학습 완료 후
terraform destroy
```

## 로그 그룹에 대해 알아둘 점

이 브랜치는 로그 그룹 4종(`application`, `system`, `access`, `error`)을 만듭니다.
이름 규칙은 CloudTrail 모듈과 동일하게 `/프로젝트/환경/용도` 형식입니다.

```
/tf-study/dev/application
/tf-study/dev/system
/tf-study/dev/access
/tf-study/dev/error
```

**단, 로그 그룹은 만들어지지만 실제 로그는 쌓이지 않습니다.**
EC2에 CloudWatch Agent를 설치하고 IAM 권한을 주어야 인스턴스의 로그 파일이
CloudWatch로 전송되기 때문입니다. 이 브랜치는 Terraform으로 로그 **수집 기반**을
구성하는 것까지를 범위로 합니다.

직접 로그를 넣어보고 싶다면 AWS CLI로 테스트 이벤트를 넣을 수 있습니다.

```bash
LOG_GROUP=$(terraform output -json log_groups | jq -r .application)

aws logs create-log-stream \
  --log-group-name "$LOG_GROUP" --log-stream-name test-stream

aws logs put-log-events \
  --log-group-name "$LOG_GROUP" --log-stream-name test-stream \
  --log-events timestamp=$(date +%s000),message="ERROR test message"
```

`ERROR` 문자열은 cloudwatch 모듈의 Metric Filter가 잡아내어
`ApplicationErrorCount` 메트릭으로 집계됩니다.

---

[← 메인 README](https://github.com/solzip/terraform-aws-study) | [← 이전: 07-security-advanced](https://github.com/solzip/terraform-aws-study/tree/07-security-advanced) | [다음: 09-ci-cd →](https://github.com/solzip/terraform-aws-study/tree/09-ci-cd)

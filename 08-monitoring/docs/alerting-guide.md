# 알림 설정 가이드 (Alerting Guide)

## 알림 흐름

```
메트릭 임계값 초과
  → CloudWatch Alarm 발생
    → SNS Topic에 메시지 발행
      → 구독자에게 전달
        ├── 이메일
        ├── SMS
        ├── Slack (Lambda/HTTPS)
        └── PagerDuty (HTTPS)
```

## 알람 목록

### Warning (경고) 알람

| 알람 이름 | 메트릭 | 임계값 | 평가 기간 | 설명 |
|-----------|--------|--------|-----------|------|
| cpu-high | CPUUtilization | 80% | 5분 × 2회 | CPU 과부하 |
| network-out-high | NetworkOut | 100MB | 5분 × 2회 | 네트워크 이상 |
| app-errors | ApplicationErrorCount | 10건 | 5분 × 1회 | 앱 에러 급증 |

### Critical (긴급) 알람

| 알람 이름 | 메트릭 | 임계값 | 평가 기간 | 설명 |
|-----------|--------|--------|-----------|------|
| status-check-failed | StatusCheckFailed | > 0 | 1분 × 1회 | 인스턴스 장애 |
| root-login-detected | RootAccountLogin | > 0 | 1분 × 1회 | 루트 로그인 |

## SNS 구독 설정

### 이메일 구독
```hcl
# terraform.tfvars에서 설정
alarm_email = "your-email@example.com"
```

terraform apply 후 이메일 확인 필수! "Confirm subscription" 클릭

### Slack 연동 (수동 설정)

1. Slack에서 Incoming Webhook URL 생성
2. AWS Lambda 함수 생성 (SNS → Slack 변환)
3. Lambda를 SNS Topic에 구독

```
SNS Topic → Lambda Function → Slack Webhook → Slack Channel
```

## 알람 대응 가이드

### CPU 높음 (cpu-high)
1. EC2 콘솔에서 CPU 사용률 확인
2. `top` 명령으로 CPU를 많이 사용하는 프로세스 확인
3. 원인에 따라 조치:
   - 트래픽 급증 → Auto Scaling 설정 고려
   - 프로세스 이상 → 해당 프로세스 재시작
   - 리소스 부족 → 인스턴스 타입 업그레이드

### StatusCheck 실패 (status-check-failed)
1. **System Status Check 실패** (AWS 인프라 문제)
   - 인스턴스 중지 후 시작 (Stop → Start)
   - 다른 물리 서버로 마이그레이션됨
2. **Instance Status Check 실패** (OS 문제)
   - 인스턴스 재부팅 시도
   - 시스템 로그 확인: `cat /var/log/messages`

### 루트 로그인 감지 (root-login-detected)
1. **즉시 확인**: 본인이 로그인한 것인지 확인
2. **비인가 접근 시**:
   - 루트 비밀번호 즉시 변경
   - MFA 재설정
   - IAM 정책 검토
   - CloudTrail 로그로 수행된 작업 확인

## 알람 테스트 방법

### CPU 알람 테스트
```bash
# EC2에 SSH 접속 후 CPU 부하 생성
stress --cpu 2 --timeout 600
# 또는
dd if=/dev/zero of=/dev/null &
```

### StatusCheck 알람 테스트
- AWS 콘솔에서 수동으로 알람 상태를 변경하여 테스트
- 실제 장애를 유발하는 것은 권장하지 않음

## 모니터링 모범 사례

1. **의미 있는 알람만 설정**: 너무 많은 알람 = 알람 피로 (Alert Fatigue)
2. **심각도 분리**: Warning과 Critical을 구분하여 다른 채널로 전달
3. **런북 작성**: 각 알람에 대한 대응 절차를 문서화
4. **정기 검토**: 알람 임계값을 실제 트래픽 패턴에 맞게 조정
5. **테스트**: 알림이 정상적으로 전달되는지 주기적으로 테스트

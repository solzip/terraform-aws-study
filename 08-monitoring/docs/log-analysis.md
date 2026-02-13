# 로그 분석 가이드 (Log Analysis Guide)

## CloudWatch Logs Insights

CloudWatch Logs Insights는 로그 데이터를 SQL과 유사한 쿼리 언어로 분석하는 도구입니다.

### 기본 쿼리 문법

```
fields @timestamp, @message     # 표시할 필드 선택
| filter @message like /ERROR/  # 필터 조건
| sort @timestamp desc          # 정렬
| limit 20                      # 결과 제한
```

### 유용한 쿼리 예시

#### 1. 최근 에러 로그 조회
```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50
```

#### 2. HTTP 5xx 에러 통계
```
fields @timestamp, @message
| filter @message like /HTTP\/1\.\d" 5\d\d/
| stats count() as errorCount by bin(30m)
| sort @timestamp desc
```

#### 3. 시간대별 로그 건수
```
stats count(*) as logCount by bin(1h)
| sort @timestamp desc
```

#### 4. 특정 IP의 접근 로그
```
fields @timestamp, @message
| filter @message like /203.0.113.50/
| sort @timestamp desc
| limit 100
```

#### 5. 응답 시간이 느린 요청 찾기
```
fields @timestamp, @message
| parse @message "* * * [*] \"*\" * * *" as ip, ident, auth, timestamp, request, status, size, responseTime
| filter responseTime > 1000
| sort responseTime desc
| limit 20
```

## CloudTrail 로그 분석

### CloudTrail 로그 구조
```json
{
  "eventVersion": "1.08",
  "userIdentity": {
    "type": "IAMUser",
    "userName": "admin"
  },
  "eventTime": "2025-02-01T12:00:00Z",
  "eventName": "RunInstances",
  "sourceIPAddress": "203.0.113.50",
  "awsRegion": "ap-northeast-2"
}
```

### 유용한 CloudTrail 쿼리

#### 1. 특정 사용자의 활동
```
fields @timestamp, eventName, sourceIPAddress
| filter userIdentity.userName = "admin"
| sort @timestamp desc
| limit 50
```

#### 2. 실패한 API 호출
```
fields @timestamp, eventName, errorCode, errorMessage
| filter errorCode != ""
| sort @timestamp desc
| limit 50
```

#### 3. Security Group 변경 이력
```
fields @timestamp, userIdentity.userName, eventName, requestParameters
| filter eventName like /SecurityGroup/
| sort @timestamp desc
```

#### 4. IAM 정책 변경 이력
```
fields @timestamp, userIdentity.userName, eventName
| filter eventName like /Policy/ or eventName like /Role/ or eventName like /User/
| sort @timestamp desc
| limit 50
```

#### 5. 콘솔 로그인 이력
```
fields @timestamp, userIdentity.userName, sourceIPAddress, responseElements.ConsoleLogin
| filter eventName = "ConsoleLogin"
| sort @timestamp desc
```

## 로그 그룹 구조

```
/${project_name}/${environment}/
├── application    # 애플리케이션 로그
├── system         # OS 시스템 로그
├── access         # 웹 서버 접근 로그
├── error          # 웹 서버 에러 로그
└── cloudtrail     # API 감사 로그
```

## Metric Filter 패턴

### 패턴 문법

| 패턴 | 설명 | 예시 |
|------|------|------|
| `"ERROR"` | 문자열 포함 | ERROR를 포함하는 라인 |
| `"ERROR -DEBUG"` | 포함 + 제외 | ERROR 포함, DEBUG 제외 |
| `[ip, ...]` | 공백 구분 필드 | Apache 로그 파싱 |
| `{ $.key = "value" }` | JSON 필드 | 구조화된 로그 |

### 활용 사례

```hcl
# 패턴 1: 단순 문자열 매칭
pattern = "ERROR"

# 패턴 2: Apache 로그에서 5xx 에러
pattern = "[ip, id, user, timestamp, request, status_code = 5*, size]"

# 패턴 3: JSON 로그에서 에러 레벨
pattern = "{ $.level = \"error\" }"

# 패턴 4: CloudTrail에서 루트 로그인
pattern = "{ $.userIdentity.type = \"Root\" && $.eventType = \"AwsConsoleSignIn\" }"
```

## 비용 최적화 팁

1. **보관 기간 설정**: 불필요하게 긴 보관 기간은 비용 증가
2. **로그 레벨 조정**: 프로덕션에서는 DEBUG 로그 비활성화
3. **S3 아카이브**: 오래된 로그는 S3 + Glacier로 이동
4. **샘플링**: 대량 로그는 샘플링하여 수집량 감소
5. **Subscription Filter**: 필요한 로그만 특정 대상으로 전달

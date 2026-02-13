# AWS 보안 점검 체크리스트 (Security Checklist)

## 1. IAM (Identity and Access Management)

### 기본 점검
- [ ] 루트 계정에 MFA(다중 인증) 설정됨
- [ ] 루트 계정의 Access Key가 삭제됨
- [ ] 모든 IAM 사용자에 MFA 활성화됨
- [ ] 불필요한 IAM 사용자가 제거됨

### 최소 권한 원칙
- [ ] IAM Policy에 와일드카드(*) 사용을 최소화했는가?
- [ ] Resource ARN을 구체적으로 지정했는가?
- [ ] Permission Boundary가 적절히 설정됨
- [ ] 서비스별 IAM Role 분리됨 (EC2, Lambda 등)

### 고급 접근 제어
- [ ] 태그 기반 접근 제어(ABAC) 적용됨
- [ ] 조건부 정책(Condition) 사용됨
- [ ] 시간 기반 접근 제어 고려됨
- [ ] VPC Endpoint 조건 적용됨 (필요시)

## 2. 데이터 암호화

### 저장 시 암호화 (Encryption at Rest)
- [ ] S3 버킷 기본 암호화 활성화됨
- [ ] EBS 볼륨 암호화됨 (Customer Managed KMS Key)
- [ ] RDS 인스턴스 암호화됨
- [ ] Secrets Manager에 KMS 키 지정됨

### 전송 중 암호화 (Encryption in Transit)
- [ ] ALB에서 HTTPS 강제 (HTTP → HTTPS 리다이렉트)
- [ ] TLS 1.2 이상만 허용
- [ ] S3 버킷 정책에 SecureTransport 조건 적용

### KMS 키 관리
- [ ] 키 로테이션 활성화됨
- [ ] 키 정책이 최소 권한 원칙을 따름
- [ ] 용도별 키 분리됨 (범용 vs Secrets 전용)
- [ ] 키 삭제 대기 기간이 적절히 설정됨

## 3. 비밀 정보 관리

### Secrets Manager
- [ ] 모든 비밀번호가 Secrets Manager에 저장됨
- [ ] 코드/Git에 비밀번호가 노출되지 않음
- [ ] 자동 로테이션이 설정됨 (프로덕션)
- [ ] Secret에 KMS 암호화 적용됨

### 금지 사항
- [ ] terraform.tfvars에 비밀번호 없음
- [ ] .env 파일에 민감 정보 없음 (또는 .gitignore에 추가)
- [ ] 하드코딩된 Access Key/Secret Key 없음
- [ ] 로그에 민감 정보가 출력되지 않음

## 4. 네트워크 보안

### Security Group
- [ ] 인바운드: 필요한 포트만 개방
- [ ] SSH(22): 특정 IP만 허용 (0.0.0.0/0 아님)
- [ ] 아웃바운드: 필요한 대상만 허용 (이상적)
- [ ] 각 규칙에 description이 작성됨

### VPC Flow Logs
- [ ] VPC Flow Logs 활성화됨
- [ ] 거부된 트래픽에 대한 알림 설정됨
- [ ] 로그 보관 기간이 적절히 설정됨
- [ ] 로그가 암호화됨 (KMS)

### 기타 네트워크
- [ ] 불필요한 퍼블릭 IP 할당 없음
- [ ] NAT Gateway를 통한 프라이빗 서브넷 아웃바운드
- [ ] NACL(Network ACL)이 적절히 설정됨 (필요시)

## 5. 모니터링 및 탐지

### GuardDuty
- [ ] GuardDuty 활성화됨
- [ ] S3 보호 활성화됨
- [ ] 맬웨어 보호 활성화됨
- [ ] Finding에 대한 알림 설정됨 (SNS)

### AWS Config
- [ ] Config Recorder 활성화됨
- [ ] EBS 암호화 규칙 적용됨
- [ ] SSH 제한 규칙 적용됨
- [ ] S3 퍼블릭 접근 규칙 적용됨
- [ ] 루트 MFA 규칙 적용됨

### Security Hub
- [ ] Security Hub 활성화됨
- [ ] AWS Foundational Security Best Practices 구독됨
- [ ] CIS AWS Foundations Benchmark 구독됨
- [ ] 정기적인 검토 스케줄 수립됨

## 6. EC2 인스턴스 보안

- [ ] IMDSv2 강제됨 (http_tokens = "required")
- [ ] IAM Instance Profile 사용 (Access Key 없음)
- [ ] 루트 볼륨 암호화됨
- [ ] 최신 AMI 사용됨
- [ ] 불필요한 포트가 열려있지 않음

## 7. 운영 보안

- [ ] CloudTrail이 모든 리전에서 활성화됨
- [ ] CloudTrail 로그가 S3에 암호화되어 저장됨
- [ ] 정기적인 보안 검토 수행
- [ ] 인시던트 대응 계획 수립됨

## 점검 주기

| 항목 | 주기 | 담당 |
|------|------|------|
| IAM 사용자 검토 | 월 1회 | 보안팀 |
| Security Group 검토 | 월 1회 | 인프라팀 |
| Config 규정 준수 확인 | 주 1회 | 보안팀 |
| GuardDuty Finding 검토 | 일 1회 | 보안팀 |
| Security Hub 점수 확인 | 주 1회 | 보안팀 |
| KMS 키 감사 | 분기 1회 | 보안팀 |
| Secret 로테이션 확인 | 월 1회 | 운영팀 |

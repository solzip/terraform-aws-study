# 프로덕션 체크리스트

## 배포 전 확인사항

### 1. 코드 품질
```
□ terraform fmt -recursive 실행 완료
□ terraform validate 통과
□ 모든 변수에 description 작성
□ 모든 변수에 validation 추가
□ 하드코딩된 값 없음 (변수로 추출)
□ 사용하지 않는 리소스/변수 제거
```

### 2. 보안
```
□ Security Group에 0.0.0.0/0 SSH 허용 없음
□ IAM Role에 최소 권한만 부여
□ State 파일 암호화 설정
□ Secrets는 tfvars가 아닌 별도 관리 (Secrets Manager 등)
□ KMS 키로 EBS 볼륨 암호화
□ 퍼블릭 접근이 필요 없는 리소스는 프라이빗 서브넷에 배치
```

### 3. 네트워크
```
□ VPC CIDR이 다른 VPC/온프레미스와 겹치지 않음
□ 서브넷이 최소 2개 가용영역에 분산
□ 라우팅 테이블이 올바르게 설정
□ DNS 설정 활성화 (enable_dns_support, enable_dns_hostnames)
```

### 4. 상태 관리
```
□ S3 Backend 설정 (원격 State)
□ DynamoDB Lock 테이블 설정
□ S3 Versioning 활성화
□ 환경별 State 파일 분리 (key 경로)
```

### 5. 모니터링
```
□ CloudWatch 상세 모니터링 활성화 (prod)
□ 알람 설정 (CPU, 상태 검사 등)
□ SNS 알림 구독 (이메일/Slack)
□ 로그 수집 설정 (CloudWatch Logs)
```

### 6. 비용 관리
```
□ 환경별 적절한 인스턴스 타입 선택
□ dev 환경은 Free Tier 범위 내
□ 사용하지 않는 리소스 Destroy
□ 태그로 비용 추적 가능
□ AWS Budget 알람 설정
```

### 7. 태그 표준
```
□ Project 태그 설정
□ Environment 태그 설정
□ ManagedBy 태그 (Terraform)
□ 추가 태그 (CostCenter, Team 등)
□ Name 태그로 식별 가능
```

---

## 환경별 차이점 비교

| 항목 | dev | staging | prod |
|------|-----|---------|------|
| VPC CIDR | 10.1.0.0/16 | 10.2.0.0/16 | 10.0.0.0/16 |
| 인스턴스 타입 | t2.micro | t2.small | t3.medium |
| 인스턴스 수 | 1 | 2 | 3 |
| 상세 모니터링 | No | Yes | Yes |
| SSH 허용 | 선택적 | No | No |
| State 관리 | Local/S3 | S3 | S3 (필수) |
| 삭제 보호 | No | 선택적 | Yes (권장) |

---

## 일반적인 실수와 방지법

### 실수 1: State 파일 로컬 관리
```
문제: 팀원 간 State 충돌, State 파일 손실
방지: S3 Backend + DynamoDB Lock 설정
```

### 실수 2: 환경 간 리소스 이름 충돌
```
문제: dev와 prod에서 같은 이름의 리소스 생성
방지: name_prefix에 환경 이름 포함 (tf-study-dev-xxx)
```

### 실수 3: 보안 그룹 전체 개방
```
문제: SSH 0.0.0.0/0 허용으로 보안 취약점
방지: validation으로 0.0.0.0/0 차단, VPN/SSM 사용
```

### 실수 4: Terraform destroy 실수
```
문제: 프로덕션 리소스를 실수로 삭제
방지: GitHub Environment 보호 규칙, lifecycle prevent_destroy
```

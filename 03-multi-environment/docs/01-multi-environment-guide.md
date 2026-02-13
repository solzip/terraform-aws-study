# 멀티 환경 관리 가이드

## 환경별 배포 순서

1. Dev 환경 먼저 배포 및 테스트
2. Staging 환경 배포 및 검증
3. Prod 환경 배포 (승인 필요)

## 환경 전환

각 환경은 독립적인 디렉토리에서 관리됩니다.

```bash
# Dev
cd environments/dev
terraform apply

# Staging
cd ../staging
terraform apply

# Prod
cd ../prod
terraform apply
```
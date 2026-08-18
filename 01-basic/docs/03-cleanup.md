# 정리 가이드

> 리소스 삭제 및 비용 방지 가이드

## 🧹 리소스 정리

### Step 1: 리소스 확인
```bash
# 관리 중인 리소스 확인
terraform state list

# 삭제 계획 확인
terraform plan -destroy
```

### Step 2: 전체 삭제
```bash
terraform destroy
```

확인 메시지에 `yes` 입력

### Step 3: AWS Console 확인
1. EC2 인스턴스 종료 확인
2. VPC 삭제 확인
3. Security Group 삭제 확인

## 🗂️ 로컬 파일 정리

### Terraform 파일 정리
```bash
# .terraform 디렉토리 삭제
rm -rf .terraform

# Lock 파일 삭제
rm .terraform.lock.hcl

# State 파일 삭제 (주의!)
rm terraform.tfstate*

# 변수 파일 삭제 (선택)
rm terraform.tfvars
```

### Git clean
```bash
# Git에서 무시되는 파일만 정리
git clean -fdX
```

## ⚠️ 주의사항

### 1. State 파일 백업
```bash
# 삭제 전 백업
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)
```

### 2. 비용 확인
- AWS Billing Dashboard 확인
- Cost Explorer로 비용 분석
- Budget Alerts 설정

### 3. 리소스 누락 확인
```bash
# EC2 인스턴스 확인
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'

# VPC 확인
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]'
```

## ✅ 정리 체크리스트

- [ ] `terraform destroy` 실행 완료
- [ ] AWS Console에서 리소스 삭제 확인
- [ ] 로컬 파일 정리 (선택)
- [ ] AWS Billing 확인

정리 완료! 다음 브랜치로: `git checkout 02-basic-localstack`
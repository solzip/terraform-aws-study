# 실행 가이드

> Terraform 명령어 상세 설명 및 트러블슈팅

## 🚀 기본 워크플로우

### 1. 초기화 (Init)
```bash
terraform init
```
- Provider 플러그인 다운로드
- Backend 초기화
- `.terraform/` 디렉토리 생성

### 2. 검증 (Validate)
```bash
terraform validate
```
- 구문 오류 확인
- 변수 참조 검증

### 3. 포맷팅 (Format)
```bash
terraform fmt
terraform fmt -recursive  # 하위 디렉토리 포함
terraform fmt -check      # 확인만
```

### 4. 계획 (Plan)
```bash
terraform plan
terraform plan -out=tfplan  # 계획 저장
```

### 5. 적용 (Apply)
```bash
terraform apply
terraform apply -auto-approve  # 확인 없이 실행
terraform apply tfplan         # 저장된 계획 실행
```

### 6. 출력 확인 (Output)
```bash
terraform output
terraform output web_url
terraform output -json
terraform output -raw instance_public_ip
```

### 7. 삭제 (Destroy)
```bash
terraform destroy
terraform destroy -auto-approve
terraform destroy -target=aws_instance.web  # 특정 리소스만
```

## 🔍 고급 명령어

### State 관리
```bash
# State 리소스 목록
terraform state list

# 리소스 상세 정보
terraform state show aws_instance.web

# State 새로고침
terraform refresh

# 리소스 제거
terraform state rm aws_instance.web

# State 이동
terraform state mv aws_instance.old aws_instance.new
```

### 특정 리소스만 작업
```bash
# 특정 리소스만 적용
terraform apply -target=aws_instance.web

# 여러 리소스 지정
terraform apply -target=aws_vpc.main -target=aws_subnet.public
```

### 로그 레벨 조정
```bash
# 디버그 모드
TF_LOG=DEBUG terraform apply

# 로그 파일로 저장
TF_LOG=TRACE TF_LOG_PATH=terraform.log terraform apply
```

## 🐛 트러블슈팅

### 문제: Provider 다운로드 실패
```bash
# 해결
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### 문제: State Lock 오류
```bash
# State lock 강제 해제 (주의!)
terraform force-unlock <LOCK_ID>
```

### 문제: 변수 누락 오류
```bash
# 명령줄에서 변수 지정
terraform apply -var="instance_type=t2.micro"

# 변수 파일 지정
terraform apply -var-file="production.tfvars"
```

### 문제: 리소스 충돌
```bash
# State import
terraform import aws_instance.web i-1234567890abcdef0

# 또는 State에서 제거 후 재생성
terraform state rm aws_instance.web
terraform apply
```

## 💡 유용한 팁

### 1. Graph 생성
```bash
terraform graph | dot -Tpng > graph.png
```

### 2. 변수 확인
```bash
terraform console
> var.aws_region
> var.instance_type
```

### 3. 빠른 테스트
```bash
# 변경사항 빠른 확인
terraform plan -target=aws_instance.web

# 특정 리소스만 재생성
terraform taint aws_instance.web
terraform apply
```

다음: [정리 가이드](03-cleanup.md)
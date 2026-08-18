# 문제 해결 가이드

## 자주 발생하는 문제

### 1. LocalStack이 시작되지 않음

**증상**: `docker-compose up`이 실패

**해결**:
```bash
# Docker 재시작
docker restart

# 포트 충돌 확인
lsof -i :4566

# 이전 컨테이너 삭제
docker-compose down -v
docker-compose up -d
```

### 2. Terraform이 LocalStack에 연결 안 됨

**증상**: `Error: error configuring Terraform AWS Provider`

**해결**:
```bash
# LocalStack 상태 확인
curl http://localhost:4566/_localstack/health

# providers-localstack.tf 확인
# 엔드포인트가 올바른지 확인
```

### 3. 리소스가 생성되지 않음

**증상**: `terraform apply` 성공했지만 리소스 없음

**해결**:
```bash
# LocalStack 로그 확인
docker-compose logs

# AWS CLI로 직접 확인
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs
```

### 4. Permission denied

**증상**: `permission denied while trying to connect to Docker`

**해결**:
```bash
sudo usermod -aG docker $USER
# 로그아웃 후 다시 로그인
```

## 디버깅 팁

```bash
# LocalStack 컨테이너 접속
docker exec -it terraform-localstack bash

# 상세 로그 활성화
docker-compose down
# docker-compose.yml에서 DEBUG=1 확인
docker-compose up

# State 파일 확인
terraform state list
terraform state show aws_vpc.main
```
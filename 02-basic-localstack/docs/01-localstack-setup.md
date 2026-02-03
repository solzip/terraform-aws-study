# LocalStack 설정 가이드

## Docker 설치

### macOS
```bash
brew install --cask docker
# Docker Desktop 실행
```

### Windows
Docker Desktop 다운로드: https://www.docker.com/products/docker-desktop

### Linux
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

## LocalStack 시작

```bash
# Docker Compose로 시작
docker-compose up -d

# 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f

# 헬스체크
curl http://localhost:4566/_localstack/health
```

## Makefile 사용 (권장)

```bash
# LocalStack 시작
make start

# 상태 확인
make health

# 전체 실행 (시작 + 배포)
make all

# 정리
make clean
```

## 트러블슈팅

### 포트 충돌
```bash
# 4566 포트 사용 중인 프로세스 확인
lsof -i :4566

# 프로세스 종료
kill -9 <PID>
```

### Docker 권한 오류
```bash
sudo chmod 666 /var/run/docker.sock
```
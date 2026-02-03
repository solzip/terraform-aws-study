# Docker 사용 가이드

## 기본 명령어

```bash
# 컨테이너 목록
docker ps

# 모든 컨테이너 (중지된 것 포함)
docker ps -a

# 로그 확인
docker logs terraform-localstack

# 컨테이너 접속
docker exec -it terraform-localstack bash

# 컨테이너 중지
docker stop terraform-localstack

# 컨테이너 삭제
docker rm terraform-localstack
```

## Docker Compose

```bash
# 시작
docker-compose up -d

# 중지
docker-compose down

# 로그
docker-compose logs -f

# 재시작
docker-compose restart

# 완전 삭제 (볼륨 포함)
docker-compose down -v
```

## 유용한 팁

### 리소스 정리
```bash
# 사용하지 않는 이미지 삭제
docker image prune

# 모든 정지된 컨테이너 삭제
docker container prune

# 시스템 전체 정리
docker system prune -a
```
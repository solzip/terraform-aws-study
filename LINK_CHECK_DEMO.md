# 링크 체커 동작 확인용 임시 문서

이 파일은 CI가 깨진 링크를 실제로 잡아내는지 확인하기 위한 것입니다.
확인이 끝나면 삭제합니다.

## 1. 정상 링크 (통과해야 함)

- [메인 README](README.md)
- [Terraform 공식 문서](https://developer.hashicorp.com/terraform/docs)

## 2. 존재하지 않는 파일 (실패해야 함)

- [없는 문서](docs/this-file-does-not-exist.md)

## 3. 존재하지 않는 외부 사이트 (실패해야 함)

- [없는 사이트](https://this-domain-definitely-does-not-exist-987654.com)

## 4. 예전에 실제로 있었던 깨진 패턴 (실패해야 함)

- [상대경로 오류](../../tree/08-monitoring)

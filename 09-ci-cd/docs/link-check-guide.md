# 링크 체커 CI 가이드

> AWS 자격증명 없이 GitHub Actions를 처음부터 끝까지 돌려보는 실습

## 왜 링크 체커로 시작하는가

이 브랜치의 다른 워크플로우(`terraform-plan.yml`, `terraform-apply.yml` 등)는
실행하려면 AWS 자격증명이 필요하고, 잘못 돌리면 실제 리소스가 생성되어 과금됩니다.
처음 GitHub Actions를 익힐 때는 부담이 큽니다.

링크 검사는 그 반대입니다.

| 항목 | Terraform 워크플로우 | 링크 체커 |
|------|---------------------|-----------|
| 자격증명 | AWS Access Key 필요 | 불필요 |
| 실패 시 영향 | 리소스가 잘못 생성될 수 있음 | 없음 |
| 실행 시간 | 수 분 | 20초 내외 |
| 비용 | AWS 과금 발생 가능 | 무료 |

즉 **워크플로우의 문법과 동작 흐름만 순수하게 학습**할 수 있습니다.

## 링크 체커가 잡아내는 문제

문서 링크는 조용히 깨집니다. 코드처럼 컴파일 에러가 나지 않기 때문에
누군가 클릭해서 404를 볼 때까지 아무도 모릅니다.

실제로 이 저장소에서 발견된 사례입니다.

| 유형 | 사례 | 원인 |
|------|------|------|
| 상대 경로 오류 | `../../tree/08-monitoring` | GitHub에서 해석되지 않는 경로 |
| 존재하지 않는 파일 | `CONTRIBUTORS.md` | 만들 예정이었으나 만들지 않음 |
| 파일명 오타 | `docs/03-cleanup.md` | 실제 파일은 `03-.cleanup.md` |
| 외부 사이트 이전 | `https://www.terraform.io/docs` | HashiCorp가 문서를 이전 (308) |

앞의 세 가지는 **내가 파일을 고칠 때** 생기므로 PR에서 잡을 수 있습니다.
마지막 하나는 **내가 아무것도 안 해도** 생기므로 주기적 실행이 필요합니다.

## 워크플로우 구조

`.github/workflows/link-check.yml` 파일 하나이며, 구조는 세 부분입니다.

```yaml
name: "Link Check"      # ① 이름 - Actions 탭에 표시

on:                     # ② 트리거 - 언제 돌 것인가
  push: ...
  pull_request: ...
  schedule: ...
  workflow_dispatch:

jobs:                   # ③ 작업 - 무엇을 할 것인가
  link-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: lycheeverse/lychee-action@v2
```

### ② 트리거를 이해하는 것이 핵심

초보자가 가장 많이 헤매는 부분입니다. 네 가지를 조합했습니다.

| 트리거 | 언제 | 목적 |
|--------|------|------|
| `push` | main에 문서 변경이 들어올 때 | 머지된 내용 확인 |
| `pull_request` | PR이 올라올 때 | **머지 전에 차단** |
| `schedule` | 매주 월요일 09:00 KST | 외부 사이트 이전 탐지 |
| `workflow_dispatch` | 버튼 누를 때 | 학습·디버깅용 |

`paths` 필터도 중요합니다.

```yaml
push:
  branches: [main]
  paths:
    - "**/*.md"        # 마크다운이 바뀐 경우에만
```

이게 없으면 `.tf` 파일만 고쳐도 링크 검사가 돕니다.
GitHub Actions는 Public 저장소에서 무료지만, 불필요한 실행은 결과를 기다리는
시간만 늘립니다.

### schedule의 함정

```yaml
schedule:
  - cron: "0 0 * * 1"    # 분 시 일 월 요일 (UTC)
```

두 가지를 기억하세요.

1. **UTC 기준입니다.** `0 0 * * 1`은 KST로 월요일 오전 9시입니다.
2. **기본 브랜치(main)에 있는 워크플로우만 실행됩니다.**
   다른 브랜치에 schedule을 넣어도 돌지 않습니다.

## 직접 돌려보기

이 파일은 지금 `09-ci-cd/.github/`에 있어서 **실행되지 않습니다.**
GitHub은 저장소 루트의 `.github/workflows/`만 읽기 때문입니다.

직접 실행해 보려면 루트로 옮기세요.

```bash
git checkout 09-ci-cd
cd ..                     # 저장소 루트로

mkdir -p .github/workflows
cp 09-ci-cd/.github/workflows/link-check.yml .github/workflows/

git add .github
git commit -m "ci: try link checker"
git push origin 09-ci-cd
```

그다음 GitHub 저장소의 **Actions 탭 > Link Check > Run workflow** 를 누릅니다.
(`workflow_dispatch`를 넣어두었기 때문에 이 버튼이 나타납니다.)

### 일부러 실패시켜 보기

CI를 배울 때는 성공보다 **실패를 보는 것**이 중요합니다.
아무 마크다운 파일에 깨진 링크를 넣고 Push해 보세요.

```markdown
[없는 파일](docs/does-not-exist.md)
[없는 사이트](https://this-domain-definitely-does-not-exist-12345.com)
```

Actions 탭에서 빨간 X와 함께 어느 파일 몇 번째 줄이 문제인지 표시됩니다.

## 제외 규칙 (.lycheeignore)

모든 링크를 검사할 수는 없습니다.
저장소 루트의 `.lycheeignore`에 제외 패턴을 정규식으로 씁니다.

```
# 로컬 실습 주소 - CI Runner에는 이 서버가 없음
^http://localhost

# 문서 예시용 플레이스홀더
^http://\$\{
```

**주의: 인라인 주석을 쓸 수 없습니다.**
lychee는 줄 전체를 정규식으로 읽습니다.

```
^http://localhost    # 이렇게 쓰면 에러
```

실제로 이 저장소에서 이 실수로 CI가 한 번 실패했습니다.

```
Error: regex parse error:
    ^http://\$\{          # http://${aws_instance.web.public_ip}
                                     ^
error: repetition quantifier expects a valid decimal
```

주석은 반드시 **별도 줄**에 쓰세요.

## 제외할 때의 판단 기준

제외 목록이 길어지면 CI가 아무것도 못 잡습니다. 다음만 제외하세요.

- **실행 환경에 없는 주소** — `localhost`, LocalStack 엔드포인트
- **문서 예시용 자리표시자** — `http://${var.public_ip}` 같은 것
- **봇을 차단하는 사이트** — Facebook 등은 자동 요청을 로그인 페이지로 보냄
- **복사해서 쓰는 템플릿** — `BRANCH_README_TEMPLATE.md`의 상대 경로는
  복사된 위치에서 유효해지므로 루트 기준 검사에서는 실패함

반대로 "가끔 실패해서 귀찮다"는 이유로 제외하면 안 됩니다.
그건 링크가 실제로 불안정하다는 신호입니다.

## 다음 단계

링크 체커로 워크플로우 구조가 익숙해졌다면
같은 디렉토리의 Terraform 워크플로우를 읽어보세요.

| 파일 | 내용 |
|------|------|
| `validate.yml` | fmt + init + validate — 링크 체커와 구조가 가장 비슷 |
| `terraform-plan.yml` | PR에 plan 결과를 코멘트로 남기는 방법 |
| `terraform-apply.yml` | 수동 승인, 환경 보호 규칙 |
| `terraform-destroy.yml` | 위험한 작업에 확인 입력을 요구하는 방법 |

`validate.yml`부터 보는 것을 권합니다.
링크 체커와 마찬가지로 "검사만 하고 아무것도 바꾸지 않는" 워크플로우입니다.

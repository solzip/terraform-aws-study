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
성공 화면은 아무것도 알려주지 않지만, 실패 화면은 도구가 무엇을 어떻게 판단하는지 보여줍니다.

아래는 이 저장소에서 실제로 해본 기록입니다. 그대로 따라 할 수 있습니다.

#### 1) 깨진 링크가 든 파일을 만들어 PR을 올린다

main을 더럽히지 않도록 테스트 브랜치에서 작업합니다.

```bash
git checkout main
git checkout -b test/link-check-demo
```

`LINK_CHECK_DEMO.md`를 만들고 **정상 링크와 깨진 링크를 섞어서** 넣습니다.
섞어야 "전부 실패"가 아니라 "깨진 것만 골라낸다"는 걸 확인할 수 있습니다.

```markdown
## 정상 링크 (통과해야 함)
- [메인 README](README.md)
- [Terraform 공식 문서](https://developer.hashicorp.com/terraform/docs)

## 없는 파일 (실패해야 함)
- [없는 문서](docs/this-file-does-not-exist.md)

## 없는 사이트 (실패해야 함)
- [없는 사이트](https://this-domain-definitely-does-not-exist-987654.com)

## 예전에 실제로 있었던 깨진 패턴 (실패해야 함)
- [상대경로 오류](../../tree/08-monitoring)
```

```bash
git add LINK_CHECK_DEMO.md
git commit -m "test: 링크 체커 동작 확인"
git push -u origin test/link-check-demo
gh pr create --base main --title "test: 링크 체커 동작 확인" --body "머지하지 않음"
```

#### 2) PR에 뜨는 체크 결과

PR을 올리자마자 `pull_request` 트리거가 걸리고, **6초 만에** 결과가 나왔습니다.

```
Check current ref           fail       6s
Check ${{ matrix.branch }}  skipping   0s
```

두 번째 줄이 `skipping`인 것도 의도한 동작입니다.
전체 브랜치 검사 Job에는 다음 조건이 걸려 있어서 PR에서는 건너뜁니다.

```yaml
if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
```

매 PR마다 11개 브랜치를 도는 것은 낭비이기 때문입니다.

#### 3) 실제 실패 로그

Actions 실행 요약에 아래 표가 그대로 출력됩니다.

```
# Summary

| Status         | Count |
|----------------|-------|
| 🔍 Total       | 35    |
| 🔗 Unique      | 28    |
| ✅ Successful  | 31    |
| ⏳ Timeouts    | 0     |
| 🔀 Redirected  | 0     |
| 👻 Excluded    | 1     |
| ❓ Unknown     | 0     |
| 🚫 Errors      | 3     |
| ⛔ Unsupported | 0     |

## Errors per input

### Errors in LINK_CHECK_DEMO.md

* [ERROR] <file:///home/runner/work/terraform-aws-study/terraform-aws-study/docs/this-file-does-not-exist.md> (at 13:3) | File not found. Check if file exists and path is correct
* [ERROR] <file:///home/runner/work/tree/08-monitoring> (at 21:3) | File not found. Check if file exists and path is correct
* [ERROR] <https://this-domain-definitely-does-not-exist-987654.com/> (at 17:3) | Connection failed. Check network connectivity and firewall settings

##[error]Process completed with exit code 2.
```

#### 4) 이 로그에서 읽어낼 것

**링크 35개 중 정확히 3개만 실패했습니다.** 정상 링크 2개는 통과했습니다.
"뭔가 깨졌다"가 아니라 **어느 파일 몇 번째 줄 몇 번째 칸**인지까지 알려줍니다.
`(at 13:3)`은 13번째 줄 3번째 칸이라는 뜻입니다.

에러 메시지가 두 종류인 것도 눈여겨보세요.

| 메시지 | 의미 |
|--------|------|
| `File not found` | 상대 경로 검사 — 그 위치에 파일이 없음 |
| `Connection failed` | 외부 URL 검사 — 실제로 HTTP 요청을 보냈으나 실패 |

**가장 중요한 한 줄은 이것입니다.**

```
<file:///home/runner/work/tree/08-monitoring>
```

문서에 쓴 링크는 `../../tree/08-monitoring`이었는데,
저장소 디렉토리를 **밖으로 빠져나가** `/home/runner/work/tree/...`로 해석됐습니다.
저장소 경로는 `/home/runner/work/terraform-aws-study/terraform-aws-study/`이므로
`../../`가 두 단계를 거슬러 올라가 버린 것입니다.

이 저장소의 브랜치 README들이 실제로 이 패턴을 쓰고 있었고,
GitHub에서 전부 404였습니다. 사람 눈으로는 그럴듯해 보여 놓치기 쉬운데
체커는 바로 잡아냅니다.

`👻 Excluded 1`은 `.lycheeignore`가 걸러낸 항목입니다. 제외 규칙도 함께 동작합니다.

#### 5) 정리

확인이 끝나면 머지하지 말고 닫습니다.

```bash
gh pr close <PR번호> --delete-branch
```

> 실제 기록:
> [PR #1](https://github.com/solzip/terraform-aws-study/pull/1) ·
> [실패한 실행 로그](https://github.com/solzip/terraform-aws-study/actions/runs/32112478232)
>
> PR은 닫혔고 브랜치도 삭제됐지만 기록은 남아 있어 지금도 실패 화면을 볼 수 있습니다.

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

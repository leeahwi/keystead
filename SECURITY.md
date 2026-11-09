# 보안 정책

Keystead는 비밀번호를 다루는 앱이라 보안 문제는 다른 버그보다 먼저 봐요. 찾은 문제가 있다면 아래 방법으로 알려 주세요.

## 신고하는 법

- **공개 이슈로 올리지 마세요.** 고치기 전에 다른 사람이 악용할 수 있어요.
- 이 저장소의 **Security 탭 → Report a vulnerability**(GitHub 비공개 신고)로 보내 주세요.
- 담아 주면 좋은 것: 영향받는 버전과 OS, 다시 해 보는 순서, 무엇이 새거나 우회되는지.
- **실제 비밀번호 · 비밀 키 · 금고 파일은 보내지 마세요.** 새로 만든 연습용 금고로 재현해 주세요.

## 이렇게 처리해요

| 단계 | 목표 |
|---|---|
| 받았다는 답 | 7일 안 |
| 판단과 계획 공유 | 14일 안 |
| 고친 판 공개 | 심각도에 따라, 늦어도 90일 안. 공개 시점은 신고한 분과 맞춰요 |

고친 판의 릴리스 노트 **보안** 칸에 영향받는 버전, 심각도, 무엇을 막고 무엇은 못 막는지, 업데이트 권고를 적어요.

## 지원하는 버전

가장 최신 판만 고쳐요. 오래된 판을 쓰고 있다면 최신 판으로 바꿔 주세요.

## 범위

**대상**
- Mac 앱과 Windows 앱, 금고 파일 형식
- 릴리스 파일과 서명 · 확인 과정(`SHA256SUMS`, `SHA256SUMS.sig`, `scripts/verify-release.*`)
- 이 저장소의 소개 페이지

**대상이 아닌 것** (설계상 막을 수 없는 것)
- 이미 악성코드에 장악된 컴퓨터(키로거, 메모리 덤프, 같은 사용자 권한의 프로세스)
- 잠금이 풀린 상태로 자리를 비운 컴퓨터에 대한 물리적 접근
- 사용자가 마스터 비밀번호 · 비밀 키를 직접 넘긴 경우

## 하지 말아 주세요

- 다른 사람의 컴퓨터 · 금고 · 계정에 대한 시도
- 서비스 거부, 스팸, 사회공학, 물리적 공격
- 신고를 마치기 전의 공개

## 릴리스 확인

릴리스마다 `SHA256SUMS`와 릴리스 키 서명(`SHA256SUMS.sig`)을 함께 올려요. 공개 키는 [.github/release-signing/](.github/release-signing/)에 있고, 지문은 [README](README.md#받은-파일이-진짜인지-확인하기-권장)에 있어요. v0.8.0부터는 개발자 Mac의 보안 칩 안에 있는 키로 서명해요. 이 키는 칩 밖으로 꺼낼 수 없고, 서명할 때마다 Touch ID를 물어요.

```sh
scripts/verify-release.sh ~/Downloads/keystead-v0.9.0
```

---

**English (short):** Please report vulnerabilities privately through this repository's **Security → Report a vulnerability**, not as public issues. We acknowledge within 7 days and aim to ship a fix within 90 days, coordinating disclosure with you. Only the latest release is supported. Compromised machines and physical access to an unlocked session are out of scope. Never send real passwords, Secret Keys or vault files; reproduce with a made-up vault.

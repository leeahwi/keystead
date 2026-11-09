#!/usr/bin/env bash
# Verify downloaded release files before installing (macOS / Linux).
#   scripts/verify-release.sh <folder with SHA256SUMS, SHA256SUMS.sig and the files> [expected version, e.g. v0.9.0]
# 1) SHA256SUMS must carry a valid signature from the pinned release key (retired keys stop at their valid-before date)
# 2) the version written inside SHA256SUMS ("# keystead vX.Y.Z", signed with it) must match the version you expected —
#    given as the second argument, or read from a folder named like keystead-v0.9.0 — and every file name, so an
#    older signed release can't be passed off as the latest
# 3) every file you downloaded must match its hash in SHA256SUMS
# 4) a Keystead file that SHA256SUMS doesn't list (e.g. a renamed or swapped installer) fails, and so does a folder
#    where nothing matched — "all checked" only when something was actually checked
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-.}"
EXPECT="${2:-}"
SIGNERS="$HERE/.github/release-signing/allowed_signers"
NS="securevault-release"

[ -f "$SIGNERS" ] || { echo "공개 키 파일이 없습니다: $SIGNERS"; exit 2; }
cd "$DIR"
[ -f SHA256SUMS ] && [ -f SHA256SUMS.sig ] || { echo "SHA256SUMS 와 SHA256SUMS.sig 를 같이 내려받으세요."; exit 2; }

if ssh-keygen -Y verify -f "$SIGNERS" -I "$NS" -n "$NS" -s SHA256SUMS.sig < SHA256SUMS >/dev/null 2>&1; then
  echo "✔ 서명 확인: SHA256SUMS 는 Keystead 릴리스 키로 서명됐습니다."
else
  echo "✘ 서명이 맞지 않습니다. 이 파일들을 설치하지 마세요."; exit 1
fi

rel="$(sed -n 's/^# keystead \(v[0-9][0-9.]*\)$/\1/p' SHA256SUMS | head -1)"
if [ -z "$EXPECT" ]; then
  case "$(basename "$(pwd)")" in *-v[0-9]*) EXPECT="v$(basename "$(pwd)" | sed 's/.*-v//')" ;; esac
  [ -n "$EXPECT" ] && echo "  (폴더 이름에서 기대 버전 $EXPECT 을 읽었습니다)"
fi
if [ -n "$rel" ]; then
  echo "✔ 버전: $rel (서명된 목록에 적힌 버전)"
else
  echo "! 목록에 버전이 없는 예전 릴리스입니다(0.8.x 이전). 릴리스 페이지의 최신 판인지 확인하세요."
fi
if [ -n "$EXPECT" ] && [ -n "$rel" ] && [ "v${EXPECT#v}" != "$rel" ]; then
  echo "✘ 기대한 버전(v${EXPECT#v})이 아니라 $rel 입니다. 예전 판을 최신으로 속인 것일 수 있어요. 설치하지 마세요."; exit 1
fi

want="${EXPECT#v}"; [ -n "$want" ] || want="${rel#v}"
status=0
checked=0
listed=" "
while read -r sum name; do
  case "$sum" in \#*) continue ;; esac
  listed="$listed$name "
  if [ -n "$want" ]; then # an old release has no version line, but its file names still give it away
    case "$name" in *"$want"*) ;; *) echo "✘ $name 은 v$want 파일이 아닙니다"; status=1 ;; esac
  fi
  [ -f "$name" ] || continue
  got="$(shasum -a 256 "$name" | cut -d' ' -f1)"
  checked=$((checked + 1))
  if [ "$got" = "$sum" ]; then echo "✔ $name"; else echo "✘ $name 해시가 다릅니다"; status=1; fi
done < SHA256SUMS
shopt -s nullglob nocaseglob
for f in *keystead* *securevault*; do
  case "$f" in SHA256SUMS|SHA256SUMS.sig) continue ;; esac
  case "$listed" in *" $f "*) ;; *) echo "✘ $f 는 SHA256SUMS 에 없는 파일입니다"; status=1 ;; esac
done
if [ $checked -eq 0 ]; then echo "✘ 확인한 파일이 없습니다. 설치 파일을 SHA256SUMS 와 같은 폴더에 두세요."; exit 1; fi
[ $status -eq 0 ] && echo "모두 확인했습니다." || echo "표시된 파일은 설치하지 마세요."
exit $status

#!/usr/bin/env bash
# heesun 세션 Stop 훅.
# 0) heesun/* 브랜치가 아직 없을 때: 세션 첫 질문 "heesun 님이신가요?"에 맞다고 답했으면, 브랜치를 만들었거나 "어떤 작업을 해볼까요?"를 물어야 끝낼 수 있다
#    개발자라고 답했으면, 그 턴 안에 원격 기본 브랜치(와 현재 브랜치의 원격)를 현재 브랜치에 합쳐야 끝낼 수 있다
# heesun/* 브랜치에서:
# 1) heesun/ 밖 변경 금지  2) 작업마다 커밋 강제  3) 올리기 전까지 매 턴 끝에 "오늘 작업 끝났나요?"를 묻게 강제
input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

# 같은 이유로 이미 한 번 막았으면 무한 반복을 피하려고 놓아준다
printf '%s' "$input" | grep -q '"stop_hook_active": *true' && exit 0

block() { printf '{"decision":"block","reason":"%s"}\n' "$1"; exit 0; }
transcript=$(printf '%s' "$input" | sed -n 's/.*"transcript_path": *"\([^"]*\)".*/\1/p')

case "$branch" in
  heesun/*) ;;
  *)
    [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
    # 세션 첫 답(f)이 신원 질문이고, 마지막 사용자 메시지(u)가 그 첫 답 바로 뒤의 것이면(k == 1), 이번 턴 마지막 답(a)을 본다
    need=$(awk '/"type":"assistant"/ && /"type":"text"/ { n++; if (n == 1) f = $0; a = $0; next }
                /"type":"user"/ && !/"tool_result"/ { k = n; u = $0 }
                END { if (k != 1 || f !~ /heesun 님이신가요/) exit
                      if (u ~ /아니|아뇨|아님|개발/) print "dev"
                      else if (a !~ /어떤 작업을 해볼까요/) print "ask" }' "$transcript")
    if [ "$need" = dev ]; then
      for ref in origin/HEAD '@{u}'; do
        git rev-parse -q --verify "$ref" >/dev/null 2>&1 || continue
        git merge-base --is-ancestor "$ref" HEAD 2>/dev/null && continue
        block "개발 세션 규칙: $ref 의 최신 내용이 아직 현재 브랜치에 없다. 다른 일보다 먼저 합쳐라(origin/HEAD는 git merge --no-edit origin/HEAD, 현재 브랜치의 원격은 git pull --no-rebase). 충돌은 양쪽을 살려 해결하고, 판단이 필요하면 사용자에게 물어라."
      done
      exit 0
    fi
    [ "$need" = ask ] && block "heesun 세션 규칙: heesun이라고 답했는데 작업 공간이 아직 없다. 할 일을 말했다면 heesun/AGENTS.md 4절대로 그 주제로 브랜치를 지금 만들어라. 할 일을 말하지 않았다면 이번 답의 끝에 짧게 '어떤 작업을 해볼까요?'라고 물어라(이 문구 그대로). heesun이 아니라는 뜻이었다면 그냥 끝내도 된다."
    exit 0 ;;
esac

changes=$(git status --porcelain --untracked-files=all 2>/dev/null)
outside=$(printf '%s\n' "$changes" | grep -v '^$' | grep -v ' heesun/' | grep -v ' "heesun/')
if [ -n "$outside" ]; then
  block "heesun 세션 규칙: heesun/ 폴더 밖에 바뀐 파일이 있다. heesun이 만든 것이 아니면 되돌리고, 꼭 필요한 변경이면 되돌린 뒤 heesun/to-dev.md에 요청으로 적어라. (heesun/AGENTS.md 2절)"
fi
if [ -n "$changes" ]; then
  block "heesun 세션 규칙: 커밋하지 않은 변경이 있다. 방금 한 작업을 지금 커밋하라(작업 하나에 커밋 하나, 한국어 한 줄 메시지, git add heesun/ 만). 업로드(push)는 heesun이 오늘 작업이 끝났다고 할 때만 한다. 그다음 턴 마지막에 짧게 '오늘 작업 끝났나요?'라고 물어라."
fi

# 아직 올리지 않은 커밋이 있으면 매 턴 끝에 물어야 한다
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null)
else
  ahead=$(git rev-list --count HEAD --not --remotes=origin 2>/dev/null)
fi
[ "${ahead:-0}" -gt 0 ] || exit 0

if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  if grep '"type":"assistant"' "$transcript" | grep '"type":"text"' | tail -n 1 | grep -q '오늘 작업 끝났나요'; then
    exit 0
  fi
fi
block "heesun 세션 규칙: 아직 올리지 않은 작업이 있다. 이번 답의 맨 끝에 아주 짧게 '오늘 작업 끝났나요?'라고 물어라. 끝났다고 하면 git push -u origin $branch 로 올리고 결과를 한 줄로 알린다."

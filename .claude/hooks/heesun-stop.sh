#!/usr/bin/env bash
# heesun 세션 Stop 훅.
# 0) heesun/* 브랜치가 아직 없을 때: "heesun 님이신가요?"에 맞다고 답하면 "어떤 작업을 해볼까요?"를 묻게 강제
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
    # 마지막 사용자 메시지 직전의 답(p), 그 사용자 메시지(u), 이번 턴의 마지막 답(a)
    need=$(awk '/"type":"assistant"/ && /"type":"text"/ { a = $0; next }
                /"type":"user"/ && !/"tool_result"/ { p = a; u = $0 }
                END { if (p ~ /heesun 님이신가요/ && u !~ /아니|아뇨|아님|개발/ && a !~ /어떤 작업을 해볼까요/) print "ask" }' "$transcript")
    [ "$need" = ask ] && block "heesun 세션 규칙: heesun이라고 답했다. 다른 일 없이 이번 답의 끝에 짧게 '어떤 작업을 해볼까요?'라고 물어라(이 문구 그대로). 작업 공간 이름은 그 답을 듣고 heesun/AGENTS.md 4절대로 정한다. heesun이 아니라는 뜻이었다면 그 질문 없이 끝내도 된다."
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

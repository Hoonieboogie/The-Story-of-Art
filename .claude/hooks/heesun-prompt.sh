#!/usr/bin/env bash
# 사용자 메시지마다(UserPromptSubmit) heesun 세션 시작 흐름을 이어 준다.
# - 직전 답이 "heesun 님이신가요?"였으면: 맞다고 했을 때 "어떤 작업을 해볼까요?"부터 묻게 한다.
# - 직전 답이 "어떤 작업을 해볼까요?"였고 아직 heesun/* 브랜치가 아니면: 그 답으로 브랜치를 만들게 한다.
input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
case "$branch" in heesun/*) exit 0 ;; esac

transcript=$(printf '%s' "$input" | sed -n 's/.*"transcript_path": *"\([^"]*\)".*/\1/p')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
last=$(grep '"type":"assistant"' "$transcript" | grep '"type":"text"' | tail -n 1)

say() { printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$1"; exit 0; }

case "$last" in
  *'heesun 님이신가요'*)
    say "[heesun 세션 흐름] 이 메시지는 'heesun 님이신가요?'에 대한 답이다. heesun이라고 했다면 이번 턴에는 heesun/AGENTS.md만 읽고, 파일을 만들거나 고치지 말고, 짧게 '어떤 작업을 해볼까요?'라고만 물어라(이 문구 그대로). 작업 공간 이름은 그 답을 듣고 정한다. heesun이 아니면 저장소 AGENTS.md의 개발용 안내를 따른다." ;;
  *'어떤 작업을 해볼까요'*)
    say "[heesun 세션 흐름] 이 메시지는 heesun이 오늘 할 일이다. 다른 일보다 먼저 heesun/AGENTS.md 4절대로 그 내용을 짧은 영문 주제로 바꿔 heesun/<YYYY-MM-DD>-<주제> 브랜치를 만들고, 그 안에서 작업하라." ;;
esac
exit 0

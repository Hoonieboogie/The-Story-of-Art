#!/usr/bin/env bash
# 사용자 메시지마다(UserPromptSubmit) heesun 세션 시작 흐름을 이어 준다. heesun/* 브랜치가 생기면 작동하지 않는다.
# - 세션 첫 답("heesun 님이신가요? 맞다면 할 일도")에 대한 답이면: 할 일을 말했으면 브랜치부터, 안 했으면 "어떤 작업을 해볼까요?"만.
# - 두 번째 답이 "어떤 작업을 해볼까요?"였으면: 그 답으로 브랜치를 만들게 한다.
# 질문 문구가 설명 속에 나와도 오작동하지 않게 세션 처음 두 답만 본다.
input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
case "$branch" in heesun/*) exit 0 ;; esac

transcript=$(printf '%s' "$input" | sed -n 's/.*"transcript_path": *"\([^"]*\)".*/\1/p')
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
texts=$(grep '"type":"assistant"' "$transcript" | grep '"type":"text"')
n=$(printf '%s\n' "$texts" | grep -c .)
first=$(printf '%s\n' "$texts" | head -n 1)
last=$(printf '%s\n' "$texts" | tail -n 1)
case "$first" in *'heesun 님이신가요'*) ;; *) exit 0 ;; esac

say() { printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$1"; exit 0; }

if [ "$n" -eq 1 ]; then
  say "[heesun 세션 흐름] 이 메시지는 'heesun 님이신가요? 맞다면 어떤 작업을 할지도'에 대한 답이다. heesun이고 할 일도 말했다면 heesun/AGENTS.md를 읽고, 다른 일보다 먼저 4절대로 그 할 일을 짧은 영문 주제로 바꿔 heesun/<YYYY-MM-DD>-<주제> 브랜치를 만든 뒤 시작하라. heesun이라고만 하고 할 일은 말하지 않았다면 파일을 만들거나 고치지 말고 짧게 '어떤 작업을 해볼까요?'라고만 물어라(이 문구 그대로). heesun이 아니면 저장소 AGENTS.md의 개발용 안내를 따른다."
fi
if [ "$n" -eq 2 ]; then
  case "$last" in *'어떤 작업을 해볼까요'*)
    say "[heesun 세션 흐름] 이 메시지는 heesun이 오늘 할 일이다. 다른 일보다 먼저 heesun/AGENTS.md 4절대로 그 내용을 짧은 영문 주제로 바꿔 heesun/<YYYY-MM-DD>-<주제> 브랜치를 만들고, 그 안에서 작업하라." ;;
  esac
fi
exit 0

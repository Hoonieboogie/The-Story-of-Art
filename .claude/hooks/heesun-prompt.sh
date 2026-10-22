#!/usr/bin/env bash
# 사용자 메시지마다(UserPromptSubmit) heesun 세션 시작 흐름을 이어 준다. heesun/* 브랜치가 생기면 작동하지 않는다.
# - 세션 첫 답("heesun 님이신가요? 맞다면 할 일도")에 대한 답이면: 할 일을 말했으면 브랜치부터, 안 했으면 "어떤 작업을 해볼까요?"만.
# - 두 번째 답이 "어떤 작업을 해볼까요?"였으면: 그 답으로 브랜치를 만들게 한다.
# - 첫 질문에 개발자라고(아니·아뇨·아님·개발) 답하면: 최신 내용을 받아 오고, main과 합치지 않은 heesun 브랜치를 알린다.
# - heesun 세션 첫 답이면: 개발 담당자의 새 답변(heesun/dev-response.md, 상태 "새 답변")이 아직 전달 안 됐는지 보고 알린다.
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

if [ "$n" -eq 1 ] && printf '%s' "$input" | grep -q '"prompt": *"[^"]*\(아니\|아뇨\|아님\|개발\)'; then
  # 개발 세션: 최신 내용 받기. 현재 브랜치는 fast-forward만, 나머지는 AI가 합친다.
  if git fetch -q --prune origin 2>/dev/null; then fetched="받아 왔다."; else fetched="받지 못했다(네트워크·권한 확인)."; fi
  git rev-parse -q --verify origin/HEAD >/dev/null || git remote set-head origin -a >/dev/null 2>&1
  up=""
  if git rev-parse -q --verify '@{u}' >/dev/null 2>&1; then
    if git merge --ff-only -q '@{u}' >/dev/null 2>&1; then up="현재 브랜치는 원격과 맞췄다."
    else up="현재 브랜치가 원격과 갈라졌거나 작업 트리가 깨끗하지 않아 자동으로 못 받았다: git pull --no-rebase로 받아라."; fi
  fi
  behind=$(git rev-list --count HEAD..origin/HEAD 2>/dev/null)
  if [ "${behind:-0}" -gt 0 ]; then
    main="기본 브랜치(origin/HEAD)가 현재 브랜치보다 커밋 ${behind}개 앞서 있다. 다른 일보다 먼저 git merge --no-edit origin/HEAD로 합쳐라(충돌은 양쪽 내용을 살려 해결하고, 어느 쪽을 고를지 판단이 필요하면 사용자에게 물어라). 합치기 전에는 이번 턴을 끝낼 수 없다(Stop 훅)."
  else main="기본 브랜치 내용은 이미 현재 브랜치에 들어 있다."; fi
  hs=$(git branch -r --list 'origin/heesun/*' --no-merged origin/HEAD 2>/dev/null | sed 's/^ *//' | tr '\n' ' ' | sed 's/ *$//')
  if [ -n "$hs" ]; then hsmsg="아직 기본 브랜치에 합치지 않은 heesun 브랜치: ${hs}. 사용자에게 목록과 각 브랜치의 변경 요약을 보여 주고 합칠지 물어라."
  else hsmsg="합치지 않은 heesun 브랜치는 없다."; fi
  say "[개발 세션 시작] 사용자는 개발자다. 저장소 AGENTS.md의 개발용 안내를 따른다. 훅이 원격 최신 내용을 ${fetched} ${up} ${main} ${hsmsg} 결과를 사용자에게 짧게 알려라."
fi
if [ "$n" -eq 1 ]; then
  # 개발 담당자의 새 답변 확인: origin/HEAD의 "새 답변" 행 중, 가장 최근 합치지 않은 heesun 브랜치에서 "전달 완료"로 바뀌지 않은 것
  git fetch -q origin 2>/dev/null
  newids=$(git show origin/HEAD:heesun/dev-response.md 2>/dev/null | awk -F'|' '$5 ~ /새 답변/ {gsub(/ /,"",$2); print $2}')
  hsb=$(git branch -r --list 'origin/heesun/*' --no-merged origin/HEAD --sort=-committerdate 2>/dev/null | head -n 1 | tr -d ' ')
  doneids=""
  [ -n "$hsb" ] && doneids=$(git show "$hsb:heesun/dev-response.md" 2>/dev/null | awk -F'|' '$5 ~ /전달 완료/ {gsub(/ /,"",$2); print $2}')
  pending=$(for id in $newids; do printf '%s\n' "$doneids" | grep -qx "$id" || printf '%s ' "$id"; done)
  reply=""
  if [ -n "$pending" ]; then
    reply=" [새 답변] 개발 담당자의 새 답변이 있다(ID: ${pending}). 다른 일보다 먼저 git show origin/HEAD:heesun/dev-response.md 로 해당 행을 읽고, heesun이 아니라고 확인되면 무시하라. heesun이면 '질문에 대한 답이 왔어요'라고 알리며 질문과 답변 내용을 쉬운 말로 전하라. 작업 브랜치를 만든 뒤 heesun/dev-response.md(브랜치 바탕에 없으면 origin/HEAD 것을 git show로 가져와 만든다)에서 해당 행 상태를 '전달 완료'로 바꿔 저장(커밋)하라."
  fi
  say "[heesun 세션 흐름] 이 메시지는 'heesun 님이신가요? 맞다면 어떤 작업을 할지도'에 대한 답이다. heesun이고 할 일도 말했다면 heesun/AGENTS.md를 읽고, 다른 일보다 먼저 4절대로 그 할 일을 짧은 영문 주제로 바꿔 heesun/<YYYY-MM-DD>-<주제> 브랜치를 만든 뒤 시작하라. heesun이라고만 하고 할 일은 말하지 않았다면 파일을 만들거나 고치지 말고 짧게 '어떤 작업을 해볼까요?'라고만 물어라(이 문구 그대로). heesun이 아니면 저장소 AGENTS.md의 개발용 안내를 따른다.${reply}"
fi
if [ "$n" -eq 2 ]; then
  case "$last" in *'어떤 작업을 해볼까요'*)
    say "[heesun 세션 흐름] 이 메시지는 heesun이 오늘 할 일이다. 다른 일보다 먼저 heesun/AGENTS.md 4절대로 그 내용을 짧은 영문 주제로 바꿔 heesun/<YYYY-MM-DD>-<주제> 브랜치를 만들고, 그 안에서 작업하라." ;;
  esac
fi
exit 0

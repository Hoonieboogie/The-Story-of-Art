#!/usr/bin/env bash
# Write/Edit 전 검사(PreToolUse).
# - heesun 세션(브랜치 heesun/*): heesun/ 밖 파일 쓰기를 막는다.
# - 그 밖의 브랜치: heesun/ 안 파일(규칙 문서 제외) 쓰기를 막는다. heesun은 반드시 heesun/<postfix> 브랜치를 만든 뒤 작업한다.
input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
path=$(printf '%s' "$input" | sed -n 's/.*"file_path": *"\([^"]*\)".*/\1/p')
[ -n "$path" ] || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null)
rel=${path#"$root"/}

deny() { printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"; exit 0; }

case "$branch" in
  heesun/*)
    case "$rel" in heesun/*) exit 0 ;; esac
    deny "heesun 세션에서는 heesun/ 폴더 안만 고칠 수 있다. 필요한 변경은 heesun/to-dev.md에 요청으로 적어라." ;;
  *)
    case "$rel" in
      heesun/AGENTS.md) exit 0 ;;
      heesun/*) deny "heesun 작업은 heesun/<날짜-주제> 브랜치에서만 한다. heesun/AGENTS.md 4절대로 브랜치를 먼저 만들어라." ;;
    esac ;;
esac
exit 0

# The Story of Art

곰브리치 『서양 미술사(The Story of Art)』 공부 저장소.

## 세션 시작 규칙 (모든 AI 에이전트, 반드시 먼저)

1. 다른 일을 하기 전에 사용자에게 **"혹시 heesun 님이신가요?"** 라고 먼저 묻는다. 대답을 듣기 전에는 파일을 읽거나 바꾸지 않는다.
2. **heesun이면:** [heesun/AGENTS.md](heesun/AGENTS.md)를 읽고 그 규칙만 따른다. 먼저 "어떤 작업을 해볼까요?"라고 묻고, 그 답으로 `heesun/<날짜-주제>` 브랜치를 만들어 그 안에서만 작업한다. heesun에게는 개발 용어를 절대 쓰지 않는다. 작업마다 커밋하고, 매 턴 끝에 "오늘 작업 끝났나요?"를 묻고, 끝났다고 하면 푸시한다(훅이 강제한다).
3. **heesun이 아니면:** 아래 개발용 안내를 따른다.

이 규칙은 Claude Code 훅으로도 강제된다(`.claude/settings.json`, `.claude/hooks/`). 표는 [heesun/AGENTS.md](heesun/AGENTS.md) 8절. 문구를 바꾸면 훅 파일도 같이 고친다.

## 개발용 안내

- **새 세션 시작:** [docs/status/AGENTS.md](docs/status/AGENTS.md) (진행 상황, 다음 작업)
- 문서 찾기: [docs/AGENTS.md](docs/AGENTS.md)
- 웹사이트 시제품: [prototype/AGENTS.md](prototype/AGENTS.md)
- 문서 작성 규칙: [docs/documentation-rules.md](docs/documentation-rules.md)
- 기획·마케팅 자료(heesun): [heesun/](heesun/AGENTS.md). 개발 세션은 이 폴더를 읽기만 한다(훅이 쓰기를 막는다, 규칙 문서 제외). heesun 브랜치(`heesun/*`)는 개발 담당자가 확인한 뒤 기본 브랜치에 합친다.

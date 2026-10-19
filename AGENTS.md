# The Story of Art

곰브리치 『서양 미술사(The Story of Art)』 공부 저장소.

## 세션 시작 규칙 (모든 AI 에이전트, 반드시 먼저)

1. 다른 일을 하기 전에 사용자에게 **"혹시 heesun 님이신가요?"** 라고 먼저 묻는다. 대답을 듣기 전에는 파일을 읽거나 바꾸지 않는다.
2. **heesun이면:** [heesun/AGENTS.md](heesun/AGENTS.md)를 읽고 그 규칙만 따른다. 아래 개발용 안내는 heesun이 따로 부탁할 때만 쓴다.
3. **heesun이 아니면:** 아래 개발용 안내를 따른다.

이 규칙은 Claude Code의 SessionStart 훅(`.claude/settings.json` → `.claude/hooks/session-start.json`)으로도 세션마다 주입된다. 문구를 바꾸면 두 곳을 같이 고친다.

## 개발용 안내

- **새 세션 시작:** [docs/status/AGENTS.md](docs/status/AGENTS.md) (진행 상황, 다음 작업)
- 문서 찾기: [docs/AGENTS.md](docs/AGENTS.md)
- 웹사이트 시제품: [prototype/AGENTS.md](prototype/AGENTS.md)
- 문서 작성 규칙: [docs/documentation-rules.md](docs/documentation-rules.md)
- 기획·마케팅 자료(heesun): [heesun/](heesun/AGENTS.md). 개발 세션은 이 폴더를 읽기만 하고, heesun이 부탁하지 않으면 고치지 않는다.

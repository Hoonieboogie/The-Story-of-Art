# prototype 룩업테이블

웹사이트 시제품. 기획은 [docs/website/](../docs/website/AGENTS.md).

| 경로 | 내용 |
| --- | --- |
| [emblems/](emblems/index.html) | 랜딩 v2 방향 시안: 흰 벽 위 흰 책, 뒤로 지나가는 회색 제목, 표지 선 엠블럼 4종(월계관·이오니아 기둥·팔메트·아치). 미리보기: https://claude.ai/artifact/5XTMYjBimYzm8qB4bo63AX |
| [landing/](landing/index.html) | 랜딩 시제품 v2: 흰 책(three.js WebGL)이 먼저 들어오고 벽 글자 "WALK IN"(왼쪽 밖→오른쪽)과 "STAY CURIOUS"(오른쪽 밖→왼쪽)가 따로 흘러든다. 표지가 열리면 필기체 "Welcome"을 지나 퍼블릭 도메인 도판 8점이 실린 책장이 드르륵 넘어가고, 모네 | 칸딘스키 양면에서 한 장 더 넘겨 빈 양면이 열리면 카메라가 들어가 펼친 양면이 8개 시대 연표가 된다. 연표는 위 왼쪽에서 아래 오른쪽으로 내려가는 매끈한 연필 선 하나(굽이 4번)이고, 번호 없이 점 8개가 시대다. 정거장마다 실제 명화에서 윤곽을 뽑은 연필 선화가 있고, 방에 들어가면 선화가 그 그림의 같은 자리에 겹친 뒤 실제 그림이 떠오른다. 인용구는 오른쪽 면 위 오른쪽. 미리보기: https://claude.ai/artifact/BAquwU6qrRogqN7CYNBLSD |
| [landing/v1.html](landing/v1.html) | 랜딩 시제품 v1 (어두운 방, CSS 3D 책). 비교용 |

- v2 기술: three.js r128(WebGL, 스포트라이트 VSM 그림자, 엠블럼 높이 지도→노멀 맵 음각, 책등부터 각도를 적분해 길이를 보존하며 휘는 낱장), GSAP 3.12.5(타임라인). 엠블럼은 스크립트가 좌표로 그려 SVG와 캔버스에 같이 쓴다.
- 화면 확인: 래퍼 `<head>`에 `window.__pauseIntro=true`를 넣으면 타임라인이 멈춘 채 시작한다. `__intro.tl.seek(초)` 후 `__intro.render()`로 원하는 순간을 찍는다(소프트웨어 WebGL이라 느리다). 연표 선 그리기는 `__intro.trail`(GSAP 타임라인)로 멈추거나 넘길 수 있다. 선화 생성 스크립트는 저장소에 없다(XDoG: 가우시안 차 + TV 잡음 제거, 크롭 좌표는 `ERAS[].crop`).
- `landing/index.html`은 아티팩트 형식이라 `<!doctype>`, `<head>`, `<body>` 태그가 없다. 로컬에서 볼 때는 브라우저가 알아서 감싼다.
- `landing/img/`: 위키미디어 커먼즈 이미지와 `plate-vermeer.jpg`(메트로폴리탄 미술관 오픈 액세스, 퍼블릭 도메인). `eraN.jpg`(세부, 480×640)는 이제 v1에서만 쓰고, `eraN-full.jpg`는 방 입장용 전체. `sketch-eraN.png`는 연표 선화(그림에서 XDoG로 윤곽을 뽑음, 모네는 손으로 따라 그림), `era4-vitruvian.jpg`는 르네상스 방 그림. 출처는 페이지의 "도판 출처"에 있다.

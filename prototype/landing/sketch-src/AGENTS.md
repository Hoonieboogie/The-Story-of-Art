# sketch-src 룩업테이블

랜딩 연표 선화 8점의 원본 좌표와 생성 스크립트. 진행 상황과 남은 개선점은 [docs/website/landing-sketches.md](../../../docs/website/landing-sketches.md).

| 파일 | 내용 |
| --- | --- |
| `trace.py` | 손으로 찍은 좌표(가로 100 단위)를 매끈한 곡선으로 바꿔 SVG 경로로 내보낸다. `python3 trace.py hv.json` → `out/` |
| `hb.json` | 건축 3점: `hy` 피라미드, `hp` 파르테논(정면도, 사진과 겹치지 않음), `hn` 노트르담 |
| `hv.json` | 베르메르, 「진주 귀걸이를 한 소녀」 |
| `hw.json` | 프리드리히, 「안개 바다 위의 방랑자」 |
| `hs.json` | 반 고흐, 「별이 빛나는 밤」 |
| `hm.json` | 몬드리안, 「빨강, 파랑, 노랑의 구성 II」 (색은 빗금 촘촘함으로) |
| `vit.py`, `skel.py` | 「비트루비우스적 인간」: 원본 소묘의 잉크를 뼈대로 추출해 경로로 만든다. `python3 vit.py 0.05 40` |

- 좌표 형식: `[[x,y],...]`는 곡선, `{"poly": ...}`는 직선, `{"circle": [cx,cy,r]}`는 원. 단위는 그림 너비 100 기준.
- 결과(`out/out.json`의 `d`)를 `index.html`의 `SKETCHES`에 넣는다. 피라미드와 방랑자는 `SKETCHES`에서 viewBox를 잘라 썼다.
- 필요 패키지: `pillow`, `numpy`, `scikit-image`. 확인용 렌더는 Playwright로 SVG를 원본 위에 겹쳐 본다.

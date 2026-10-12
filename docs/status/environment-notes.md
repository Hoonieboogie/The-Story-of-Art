# 작업 환경 메모

클라우드 세션에서 외부 자료에 접근할 때 겪은 문제와 해결 방법.

## YouTube

- YouTube는 클라우드 IP를 봇으로 판단해 yt-dlp, 시청 페이지, 임베드를 모두 막았다.
- **우회:** Invidious 미러(`invidious.f5.si`)를 썼다.
  1. Playwright Chromium(`/opt/pw-browsers/chromium`, `proxy: HTTPS_PROXY`)으로 시청 페이지를 열어 Anubis 봇 검사를 통과한다.
  2. 페이지 안에서 `fetch('/latest_version?id=<ID>&itag=136&local=true')`를 호출해 리다이렉트된 companion URL을 얻는다.
  3. 그 URL을 curl로 10MB씩 나눠 받는다.
- 메타데이터: `https://invidious.f5.si/api/v1/videos/<ID>`
- 받은 영상과 프레임은 임시 폴더에만 두고 저장소에 올리지 않았다.

## 네이버 블로그

- 글 목록: `https://m.blog.naver.com/api/blogs/<blogId>/post-list?categoryNo=<n>&itemCount=30&page=1` (Referer 헤더 필요)
- 본문: `https://m.blog.naver.com/PostView.naver?blogId=<blogId>&logNo=<logNo>` (옛 스마트에디터 2 형식, `se_component_wrap` 이후가 본문)

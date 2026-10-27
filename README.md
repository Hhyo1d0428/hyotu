# 효투의 돈달력

20일~다음 달 19일 급여 기간 달력, 카테고리 예산, 이월·분할 이동, 저축·회수, 환불, 반복 지출, 통계, 검색, JSON 백업·복원, CSV 내보내기를 제공하는 개인 가계부입니다.

- React + TypeScript + Vite
- Supabase Auth(Google) + PostgreSQL JSON 문서 저장
- 사용자 접근 제한(RLS) + 허용 이메일 목록 + revision 비교 저장
- GitHub Pages 호환 상대 경로 / 홈 화면 웹앱 manifest·아이콘
- 서버 미연결 시 실제 계정으로 가장하지 않는 별도 체험 모드

**설치·Google 로그인·서버 저장 연결은 [시작안내.md](./시작안내.md)를 읽어 주세요.**

```bash
npm ci
npm run dev
npm test
npm run build
```

Node.js 22.12 이상. `dist/`가 정적 배포 결과물입니다. GitHub Actions 배포 설정도 포함되어 있습니다.

핵심 계산은 `src/ledger.ts`, 화면은 `src/main.tsx`, 저장·내보내기는 `src/store.ts`, 서버 설정은 `supabase/setup.sql`에 있습니다. 공개용 키는 `public/config.js`에 넣을 수 있습니다. secret/service_role/Google Client Secret은 코드와 저장소에 넣지 마세요.

소스 테스트에 포함된 이메일과 사용자 ID는 모두 가상 데이터입니다. 실제 계정이나 재무 기록은 포함하지 않습니다.

생활비 아래 간식·술·친구 만남 등의 하위 지출 항목을 만들 수 있습니다. 하위 항목의 지출과 환불은 상위 카테고리 예산에 함께 반영되고, 하위 항목별 사용액도 확인할 수 있습니다. 예산 화면에서 상위 카드의 **하위 항목 추가**를 누르세요.

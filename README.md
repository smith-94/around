# around

위치 기반 소셜 지도 앱 — 친구들이 어디 있는지 한눈에 보고, 마커에서 바로 메시지를 보내요.

## 주요 기능
- 📱 휴대폰 번호 OTP 인증 (Supabase Auth)
- 🗺️ 지도 기반 UI (flutter_map + OpenStreetMap)
- 🧑 마커에 프로필 사진 + 상태 메시지 표시
- 💬 마커 탭 → 미리보기 → 1:1 채팅 (실시간)
- 📍 친구 위치 실시간 공유 (Supabase Realtime)

## 폴더 구조
```
lib/
  main.dart            ── 진입점 (Supabase 초기화)
  app.dart             ── MultiProvider + AuthGate
  config/
    theme.dart         ── 색/타이포/버튼 등 디자인 시스템
    supabase_config.dart
  models/              ── UserProfile / FriendLocation / ChatMessage
  services/            ── Supabase / Auth / Profile / Location / Friends / Messages
  providers/           ── ChangeNotifier provider 4종
  screens/
    splash_screen.dart
    auth/              ── 전화번호 입력 / OTP / 프로필 셋업
    home/              ── 지도 / 친구 미리보기 시트 / 프로필 드로어
    chat/              ── 1:1 채팅
  widgets/             ── ProfileMarker, GradientBackground 등
supabase/
  schema.sql           ── 테이블 + RLS + Realtime 설정
```

## 셋업

### 1) Supabase 프로젝트
1. https://app.supabase.com 에서 프로젝트 생성
2. **SQL Editor** → `supabase/schema.sql` 내용 실행
3. **Authentication → Providers → Phone** 활성화 (Twilio 등 SMS 프로바이더 연결)
4. **Project Settings → API** 에서 URL / anon key 복사

### 2) 키 주입
`lib/config/supabase_config.dart` 의 기본값을 수정하거나, 빌드 시 dart-define 사용:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

### 3) 의존성 설치 & 실행
```bash
flutter pub get
flutter run
```

## 디자인
- 컬러: 보라 → 핑크 그라데이션 (`AppColors.primary` `AppColors.accent`)
- 폰트: Google Fonts `Inter`
- 둥근 모서리(14~28px), 가벼운 그림자, 그라데이션 말풍선

## 다음 할 일 (TODO)
- 친구 추가 / 검색 화면
- 채팅 목록 화면
- 프로필 사진 업로드 (Supabase Storage)
- 푸시 알림
# around

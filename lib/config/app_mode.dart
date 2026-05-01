enum AppMode {
  /// UI 미리보기 모드.
  /// - Supabase 초기화/호출을 모두 건너뜀
  /// - 가짜 프로필/친구/메시지로 화면을 채워서 디자인을 바로 확인할 수 있음
  uiPreview,

  /// 실 운영 모드.
  /// - Supabase 인증/실시간 연결 사용 (키 필요)
  production,
}

class AppModeConfig {
  /// 👇 여기 한 줄만 바꾸면 됩니다.
  /// UI 만 보고 싶을 때: AppMode.uiPreview
  /// 백엔드 연결되면: AppMode.production1
  static const AppMode current = AppMode.uiPreview;

  static bool get isPreview => current == AppMode.uiPreview;
  static bool get isProduction => current == AppMode.production;
}

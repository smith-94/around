import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  /// 위치 공유 (꺼지면 친구들에게 내 위치 미노출)
  bool shareLocation = true;

  /// 상태 메시지를 친구에게 노출
  bool showStatus = true;

  /// 전화번호로 다른 사람이 나를 찾을 수 있게 허용
  bool discoverable = true;

  /// 푸시 알림
  bool pushNotifications = true;

  /// 다크모드
  bool darkMode = false;

  void toggleShareLocation(bool v) {
    shareLocation = v;
    notifyListeners();
  }

  void toggleShowStatus(bool v) {
    showStatus = v;
    notifyListeners();
  }

  void toggleDiscoverable(bool v) {
    discoverable = v;
    notifyListeners();
  }

  void togglePushNotifications(bool v) {
    pushNotifications = v;
    notifyListeners();
  }

  void toggleDarkMode(bool v) {
    darkMode = v;
    notifyListeners();
  }
}

import 'package:piaf/utils/login/web_login_stub.dart'
    if (dart.library.html) 'package:piaf/chat/utils/login/web_login.dart';

/// An interface class to import without issue WebLogin methods
class WebLoginInterface {
  static String? getToken() {
    return WebLogin.getToken();
  }

  static String? getUrl() {
    return WebLogin.getUrl();
  }

  static void launchSame(String url) {
    WebLogin.launchSame(url);
  }
}

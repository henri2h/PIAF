import 'dart:html';

class WebLogin {

  static String? getToken() {
    String wurl = window.location.href;

    Uri u = Uri.parse(wurl);
    String? matrixToken = u.queryParameters["loginToken"];
  return matrixToken;
  }

  static void launchSame(String url) {
    window.location.href = url;
  }
}

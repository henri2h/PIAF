import 'package:matrix/matrix.dart';

import 'package:piaf/chat/helpers/storage_manager.dart';
import 'package:piaf/chat/utils/login/web_login_interface.dart';

extension MatrixLoginExtension on Client {
  Future<bool> customLoginAction(LoginType loginType,
      {required String homeserver,
      String? user,
      String? password,
      String? token}) async {
    await checkHomeserver(Uri.parse(homeserver));
    await login(loginType,
        identifier:
            user != null ? AuthenticationUserIdentifier(user: user) : null,
        password: password,
        token: token,
        initialDeviceDisplayName: clientName);
    return true;
  }

  String? get token => WebLoginInterface.getToken();

  /// [WEB] Whether the user has started a SSO login process. Have we a token in the url ?
  bool get shouldSSOLogin => token != null;

  Future<bool> ssoLogin() async {
    final t = token;
    String homeserverUrl = await StorageManager.readData('homeserver');

    await customLoginAction(LoginType.mLoginToken,
        homeserver: homeserverUrl, token: t);

    return true;
  }
}

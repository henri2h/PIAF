import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/Managers/StorageManager.dart';
import 'package:minestrix/utils/Managers/ThemeManager.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:provider/provider.dart';
import 'package:minestrix/utils/web/pluginWebLogin_stub.dart'
    if (dart.library.html) 'package:minestrix/utils/web/pluginWebLogin.dart';

class Minestrix extends StatefulWidget {
  @override
  _MinestrixState createState() => _MinestrixState();
}

class _MinestrixState extends State<Minestrix> {
  final _appRouter = AppRouter();
  bool _initLock = false;
  Future<bool> initMatrix(MinestrixClient m) async {
    Logs().i("[ logged ] : " + m.isLogged().toString());
    if (m.isLogged() == false && !_initLock) {
      _initLock = true;
      await m.init(
          waitForFirstSync: false, waitUntilLoadCompletedLoaded: false);

      await m.roomsLoading;
      await m.updateAll(); // load all minestrix rooms and build timeline
    }
    return true;
  }

  Future<bool> ssoLogin(MinestrixClient sclient, String token) async {
    String homeserverUrl = await StorageManager.readData('homeserver');
    String user = await StorageManager.readData('user');

    await sclient.customLoginAction(LoginType.mLoginToken,
        homeserver: homeserverUrl, user: user, token: token);

    return true;
  }

  bool loginAsWeb = false;
  @override
  Widget build(BuildContext context) {
    return Matrix(
      child: Builder(
        builder: (context) => Consumer<ThemeNotifier>(
          builder: (context, theme, _) => StreamBuilder<LoginState?>(
              stream: Matrix.of(context).sclient?.onLoginStateChanged.stream,
              builder: (context, AsyncSnapshot<LoginState?> state) {
                MinestrixClient sclient = Matrix.of(context).sclient!;

                // detect if the user did try to login with a token
                // don't try it twice !
                if (kIsWeb) {
                  if (loginAsWeb == false) {
                    String? token = WebLogin.getToken();
                    if (token != null) {
                      loginAsWeb = true;
                      return FutureBuilder(
                          future: ssoLogin(sclient, token),
                          builder: (context, snap) =>
                              CircularProgressIndicator());
                    }
                  }
                }

                return StreamBuilder<String>(
                    stream: sclient.onSRoomsUpdate.stream,
                    builder: (context, sroomSnap) => FutureBuilder(
                        future: initMatrix(sclient),
                        builder: (context, snap) {
                          return MaterialApp.router(
                            routerDelegate: AutoRouterDelegate.declarative(
                              _appRouter,
                              routes: (_) {
                                print("route up");
                                return [
                                  if (state.hasData == false ||
                                      (state.data == LoginState.loggedIn &&
                                          !sclient.userRoomCreated))
                                    MatrixLoadingRoute()
                                  else if (state.data == LoginState.loggedIn &&
                                      sclient.userRoomCreated)
                                    HomeWraperRoute()
                                  // if they are not logged in, bring them to the Login page
                                  else
                                    LoginRoute()
                                ];
                              },
                            ),

                            routeInformationParser:
                                _appRouter.defaultRouteParser(),
                            debugShowCheckedModeBanner: false,
                            // theme :
                            theme: theme.getTheme(),
                          );
                        }));
              }),
        ),
      ),
    );
  }
}

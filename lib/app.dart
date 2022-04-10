import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/login/login_extension.dart';
import 'package:provider/provider.dart';

import 'router.gr.dart';
import 'utils/managers/theme_manager.dart';
import 'utils/matrixWidget.dart';
import 'utils/minestrix/minestrixClient.dart';

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
                  if (loginAsWeb == false && sclient.shouldSSOLogin) {
                    loginAsWeb = true;
                    return FutureBuilder(
                        future: sclient.ssoLogin(),
                        builder: (context, snap) =>
                            CircularProgressIndicator());
                  }
                }

                return FutureBuilder(
                    future: initMatrix(sclient),
                    builder: (context, snap) {
                      return MaterialApp.router(
                        routerDelegate: AutoRouterDelegate.declarative(
                          _appRouter,
                          routes: (_) {
                            print("route up");
                            return [
                              if (state.hasData == false)
                                MatrixLoadingRoute()
                              else if (state.data == LoginState.loggedIn)
                                AppWrapperRoute()
                              // if they are not logged in, bring them to the Login page
                              else
                                LoginRoute()
                            ];
                          },
                        ),

                        routeInformationParser: _appRouter.defaultRouteParser(),
                        debugShowCheckedModeBanner: false,
                        // theme :
                        theme: theme.theme,
                      );
                    });
              }),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/login/login_extension.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:provider/provider.dart';

import 'router.gr.dart';
import 'utils/managers/theme_manager.dart';

class Minestrix extends StatefulWidget {
  const Minestrix({Key? key, required this.clients}) : super(key: key);

  final List<Client> clients;
  @override
  MinestrixState createState() => MinestrixState();
}

class MinestrixState extends State<Minestrix> {
  final _appRouter = AppRouter();
  bool _initLock = false;
  Future<bool> initMatrix(Client m) async {
    Logs().i("[ logged ] : ${m.isLogged()}");
    if (m.isLogged() == false && !_initLock) {
      _initLock = true;
      await m.init(
          waitForFirstSync: false, waitUntilLoadCompletedLoaded: false);
    }
    return true;
  }

  bool loginAsWeb = false;
  @override
  Widget build(BuildContext context) {
    return Matrix(
      applicationName: 'MinesTRIX',
      context: context,
      clients: widget.clients,
      child: Builder(
        builder: (context) => Consumer<ThemeNotifier>(
          builder: (context, theme, _) => StreamBuilder<LoginState?>(
              stream: Matrix.of(context).client.onLoginStateChanged.stream,
              builder: (context, AsyncSnapshot<LoginState?> state) {
                Client client = Matrix.of(context).client;

                // detect if the user did try to login with a token
                // don't try it twice !
                if (kIsWeb) {
                  if (loginAsWeb == false && client.shouldSSOLogin) {
                    loginAsWeb = true;
                    return FutureBuilder(
                        future: client.ssoLogin(),
                        builder: (context, snap) =>
                            const CircularProgressIndicator());
                  }
                }

                return FutureBuilder(
                    future: initMatrix(client),
                    builder: (context, snap) {
                      return MaterialApp.router(
                        routerDelegate: AutoRouterDelegate.declarative(
                          _appRouter,
                          routes: (_) {
                            final isLogged = client.isLogged();
                            return [
                              //if (state.hasData == false)
                              //  MatrixLoadingRoute()
                              if (isLogged)
                                const AppWrapperRoute()
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

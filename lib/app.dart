import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/router.dart';
import 'package:piaf/partials/utils/login/login_extension.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';
import 'package:provider/provider.dart';

import 'router.gr.dart';
import 'utils/managers/theme_manager.dart';

class App extends StatefulWidget {
  const App({super.key, required this.clients});

  final List<Client> clients;
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  final _appRouter = AppRouter();
  bool _initLock = false;
  Future<void> initMatrix(Client m) async {
    if (_initLock) return;

    if (!m.isLogged()) {
      Logs().i("[ logged ] [ ${m.clientName} ]: ${m.isLogged()}");
      _initLock = true;
      await m.init(
          waitForFirstSync: false, waitUntilLoadCompletedLoaded: false);
    }
    return;
  }

  Future<bool>? webLogin;

  @override
  Widget build(BuildContext context) {
    return Matrix(
      context: context,
      clients: widget.clients,
      child: Builder(
        builder: (context) => Consumer<ThemeNotifier>(
          builder: (context, theme, _) => DynamicColorBuilder(
              builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            return StreamBuilder<LoginState?>(
                stream: Matrix.of(context).client.onLoginStateChanged.stream,
                builder: (context, AsyncSnapshot<LoginState?> state) {
                  Client client = Matrix.of(context).client;

                  if (kIsWeb && client.shouldSSOLogin) {
                    webLogin ??= client.ssoLogin();
                  }

                  return FutureBuilder<bool>(
                      future: webLogin,
                      builder: (context, snapshot) {
                        // Progress indicator while login in on web
                        if (webLogin != null && !snapshot.hasData) {
                          return const MaterialApp(
                            home: Scaffold(
                              body: Center(
                                  child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(
                                    width: 12,
                                  ),
                                  Text("Loading")
                                ],
                              )),
                            ),
                          );
                        }

                        final darkTheme =
                            darkDynamic?.copyWith(surface: Colors.black) ??
                                ColorScheme.dark();

                        return FutureBuilder(
                            future: initMatrix(client),
                            builder: (context, snap) {
                              return MaterialApp.router(
                                routerConfig: _appRouter.config(),
                                theme: ThemeData(
                                    colorScheme:
                                        lightDynamic ?? ColorScheme.light(),
                                    textTheme: theme.whiteTextTheme,
                                    useMaterial3: true),
                                darkTheme: ThemeData(
                                  colorScheme: darkTheme,
                                  textTheme: theme.darkTextTheme,
                                  useMaterial3: true,
                                ),
                                themeMode: theme.mode,
                              );
                            });
                      });
                });
          }),
        ),
      ),
    );
  }
}

@RoutePage()
class MainRouterPage extends StatefulWidget {
  const MainRouterPage({super.key});

  @override
  State<MainRouterPage> createState() => _MainRouterPageState();
}

class _MainRouterPageState extends State<MainRouterPage> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return StreamBuilder<LoginState?>(
        stream: Matrix.of(context).client.onLoginStateChanged.stream,
        builder: (context, AsyncSnapshot<LoginState?> state) {
          return AutoRouter.declarative(routes: (_) {
            final isLogged = client.isLogged();
            return [
              if (isLogged)
                const AppWrapperRoute()

              // if they are not logged in, bring them to the Login page
              else if (Platform.isAndroid)
                const MobileWelcomeRouter()
              else
                DesktopLoginRoute()
            ];
          });
        });
  }
}

import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.dart';
import 'package:minestrix_chat/utils/login/login_extension.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
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
  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

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
      applicationName: 'MinesTRIX',
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
    
                        return FutureBuilder(
                            future: initMatrix(client),
                            builder: (context, snap) {
                              return MaterialApp.router(
                                routerDelegate:
                                    AutoRouterDelegate.declarative(
                                  _appRouter,
                                  routes: (_) {
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
                                  },
                                ),
                                routeInformationParser:
                                    _appRouter.defaultRouteParser(),
                                debugShowCheckedModeBanner: false,
                                theme: ThemeData(
                                  colorScheme: lightDynamic ??
                                      _defaultLightColorScheme,
                                  textTheme: theme.whiteTextTheme,
                                  useMaterial3: true,
                                ),
                                darkTheme: ThemeData(
                                  colorScheme:
                                      darkDynamic ?? _defaultDarkColorScheme,
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

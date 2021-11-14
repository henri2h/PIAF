import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/Managers/ThemeManager.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:provider/provider.dart';

class Minestrix extends StatefulWidget {
  @override
  _MinestrixState createState() => _MinestrixState();
}

class _MinestrixState extends State<Minestrix> {
  final _appRouter = AppRouter();
  @override
  Widget build(BuildContext context) {
    return Matrix(
      child: Builder(
        builder: (context) => Consumer<ThemeNotifier>(
          builder: (context, theme, _) => StreamBuilder<LoginState?>(
              stream: Matrix.of(context).sclient?.onLoginStateChanged.stream,
              builder: (context, AsyncSnapshot<LoginState?> state) {
                return MaterialApp.router(
                  routerDelegate: AutoRouterDelegate.declarative(
                    _appRouter,
                    routes: (_) {
                      return [
                        if (state.hasData == false)
                          MatrixLoadingRoute()
                        else if (state.data == LoginState.loggedIn)
                          HomeWraperRoute()
                        // if they are not logged in, bring them to the Login page
                        else
                          LoginRoute()
                      ];
                    },
                  ),

                  routeInformationParser: _appRouter.defaultRouteParser(),
                  debugShowCheckedModeBanner: false,
                  // theme :
                  theme: theme.getTheme(),
                );
              }),
        ),
      ),
    );
  }
}

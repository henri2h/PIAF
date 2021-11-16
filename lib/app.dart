import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/utils/Managers/ThemeManager.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
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
                MinestrixClient sclient = Matrix.of(context).sclient!;
                print("on login changed update");

                bool init = false;
                late MaterialApp app;

                return StreamBuilder<String>(
                    stream: sclient.onSRoomsUpdate.stream,
                    builder: (context, sroomSnap) {
                      print("sroom update");
                      print("State : " + (state.data.toString()));
                      if (init == false) {
                        init = true;
                        app = MaterialApp.router(
                          routerDelegate: AutoRouterDelegate.declarative(
                            _appRouter,
                            routes: (_) {
                              print("route up");
                              return [
                                if (state.hasData == false ||
                                    (state.data == LoginState.loggedIn &&
                                        sroomSnap.hasData == false))
                                  HomeWraperRoute() //MatrixLoadingRoute()
                                else if (state.data == LoginState.loggedIn &&
                                    sclient.userRoomCreated)
                                  HomeWraperRoute()
                                else if (state.data == LoginState.loggedIn)
                                  CreateMinestrixAccountRoute()
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
                      }
                      return app;
                    });
              }),
        ),
      ),
    );
  }
}

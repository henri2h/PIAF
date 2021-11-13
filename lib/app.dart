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
  @override
  Widget build(BuildContext context) {
    final _appRouter = AppRouter();
    return Matrix(
      child: Builder(
        builder: (context) => Consumer<ThemeNotifier>(
          builder: (context, theme, _) => StreamBuilder(
              stream: Matrix.of(context).sclient?.onLoginStateChanged.stream,
              builder: (context, AsyncSnapshot<LoginState> state) {
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

/* title: 'MinesTrix client',
            debugShowCheckedModeBanner: false,


            home: StreamBuilder<LoginState>(
              stream: Matrix.of(context).sclient.onLoginStateChanged.stream,
              builder: (BuildContext context, snapshot) {
                SClient sclient = Matrix.of(context).sclient;

                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          H1Title("MINESTRIX"),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 8),
                                H2Title("Signing in...."),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.data == LoginState.loggedIn) {
                  return StreamBuilder(
                      stream: sclient.onSRoomsUpdate.stream,
                      builder: (context, snap) {
                        if (!sclient.sroomsLoaded) {
                          return Scaffold(
                            body: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 10),
                                    Text("Loading rooms"),
                                  ],
                                ),
                                StreamBuilder<SyncStatusUpdate>(
                                  stream: sclient.onSyncStatus.stream,
                                  builder: (context, snap) {
                                    if (!snap.hasData) return Container();

                                    print("Sync progress : " +
                                        snap.data.progress.toString());

                                    return Column(
                                      children: [
                                        if (snap.data.status ==
                                            SyncStatus.processing)
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Card(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Column(
                                                  children: [
                                                    Text("Running first sync",
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    SizedBox(height: 10),
                                                    LinearProgressIndicator(
                                                        value:
                                                            snap.data.progress),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (snap.data.status !=
                                            SyncStatus.processing)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                Text("Status : " +
                                                    snap.data.status
                                                        .toString()),
                                                Text("Progress : " +
                                                    snap.data.progress
                                                        .toString()),
                                                Text("Error : " +
                                                    snap.data.error.toString()),
                                                Text(snap.connectionState.index
                                                    .toString()),
                                              ],
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        } else if (sclient.userRoom == null) {
                          return MinesTrixAccountCreation();
                        } else {
                          // we are ready :D
                          return HomeScreen();
                        }
                      });
                }
                return LoginScreen();
              },
            ),
          */

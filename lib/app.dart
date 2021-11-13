import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/global/Managers/ThemeManager.dart';
import 'package:minestrix/router.gr.dart';
import 'package:minestrix/global/smatrixWidget.dart';
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
          builder: (context, theme, _) => MaterialApp.router(
            routerDelegate: _appRouter.delegate(),
            routeInformationParser: _appRouter.defaultRouteParser(),
          ),
        ),
      ),
    );
  }
}


/* title: 'MinesTrix client',
            debugShowCheckedModeBanner: false,

            // theme :
            theme: theme.getTheme(),

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
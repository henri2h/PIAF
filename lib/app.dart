import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/Managers/ThemeManager.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/screens/createMinesTrixAccount.dart';
import 'package:minestrix/screens/home/screen.dart';
import 'package:minestrix/screens/login.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:provider/provider.dart';

class Minestrix extends StatefulWidget {
  @override
  _MinestrixState createState() => _MinestrixState();
}

class _MinestrixState extends State<Minestrix> {
  @override
  Widget build(BuildContext context) {
    return Matrix(
      child: Builder(
        builder: (context) => Consumer<ThemeNotifier>(
          builder: (context, theme, _) => MaterialApp(
            title: 'MinesTrix client',
            debugShowCheckedModeBanner: false,

            // theme :
            theme: theme.getTheme(),

            home: StreamBuilder<LoginState>(
              stream: Matrix.of(context).sclient.onLoginStateChanged.stream,
              builder: (BuildContext context, snapshot) {
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
                                H2Title("Loading...."),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.data == LoginState.loggedIn) {
                  return StreamBuilder<String>(
                      stream: Matrix.of(context).sclient.onSRoomsUpdate.stream,
                      builder: (BuildContext context, snapshot) {
                        print("Minestrix : room update building home");
                        SClient sclient = Matrix.of(context).sclient;

                        if (!sclient.sroomsLoaded) {
                          return Scaffold(
                            body: Center(
                              child: Column(
                                children: [
                                  Text("Loading rooms"),
                                  StreamBuilder<SyncStatusUpdate>(
                                    stream: sclient.onSyncStatus.stream,
                                    builder: (context, snap) {
                                      if (!snap.hasData) return Container();

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
                                                          value: snap
                                                              .data.progress),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (snap.data.status !=
                                              SyncStatus.processing)
                                            Column(
                                              children: [
                                                CircularProgressIndicator(),
                                                Text("Sync status"),
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
                                        ],
                                      );
                                    },
                                  ),
                                  StreamBuilder<bool>(
                                    stream: sclient.onFirstSync.stream,
                                    builder: (context, snap) {
                                      return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: snap.data != null && snap.data
                                              ? Icon(Icons.check)
                                              : Container());
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (sclient.userRoom == null) {
                          return MinesTrixAccountCreation();
                        } else {
                          return HomeScreen();
                        }
                      });
                }
                return LoginScreen();
              },
            ),
          ),
        ),
      ),
    );
  }
}

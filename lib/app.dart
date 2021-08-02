import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/screens/createMinesTrixAccount.dart';
import 'package:minestrix/screens/home/screen.dart';
import 'package:minestrix/screens/login.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class Minestrix extends StatefulWidget {
  @override
  _MinestrixState createState() => _MinestrixState();
}

class _MinestrixState extends State<Minestrix> {
  @override
  Widget build(BuildContext context) {
    return Matrix(
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'MinesTrix client',
          debugShowCheckedModeBanner: false,
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
                        H2Title("Loading...."),
                        CircularProgressIndicator(),
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.data == LoginState.logged) {
                return StreamBuilder<String>(
                    stream: Matrix.of(context).sclient.onSRoomsUpdate.stream,
                    builder: (BuildContext context, snapshot) {
                      print("Minestrix : room update building home");
                      SClient sclient = Matrix.of(context).sclient;

                      if (!sclient.sroomsLoaded) {
                        return Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
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
    );
  }
}

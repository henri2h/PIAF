import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/screens/createMinesTrixAccount.dart';
import 'package:minestrix/screens/home/screen.dart';
import 'package:minestrix/screens/login.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class Minetrix extends StatefulWidget {
  @override
  _MinetrixState createState() => _MinetrixState();
}

class _MinetrixState extends State<Minetrix> {
  HomeScreen hm;
  MinesTrixAccountCreation hmCreation;

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
                    child: CircularProgressIndicator(),
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
                        if (hmCreation == null)
                          hmCreation = MinesTrixAccountCreation();
                        return hmCreation;
                      } else {
                        if (hm == null) hm = HomeScreen();
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

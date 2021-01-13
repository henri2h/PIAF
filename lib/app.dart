import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/screens/createMinesTrixAccount.dart';
import 'package:minestrix/screens/home/screen.dart';
import 'package:minestrix/screens/login.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class Minetrix extends StatelessWidget {
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
              print("hasData : " + snapshot.hasData.toString());
              print(context);
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
                    stream:
                        Matrix.of(context).sclient.onTimelineUpdate.stream,
                    builder: (BuildContext context, snapshot) {
                      SClient sclient = Matrix.of(context).sclient;
                      print("sclient.userRoom exits ? : " +
                          (sclient.userRoom == null).toString());

                      if (sclient.userRoom == null)
                        return MinesTrixAccountCreation();
                      else
                        return HomeScreen();
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

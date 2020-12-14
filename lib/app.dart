import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/screens/home/screen.dart';
import 'package:minestrix/screens/login.dart';
import 'package:provider/provider.dart';

class Minetrix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<Client>(
      create: (_) => Client('MinesTrix'),
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'MinesTrix client',
          debugShowCheckedModeBanner: false,
          home: StreamBuilder<LoginState>(
            stream: Provider.of<Client>(context).onLoginStateChanged.stream,
            builder:
                (BuildContext context, AsyncSnapshot<LoginState> snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              if (snapshot.data == LoginState.logged) {
                return HomeScreen();
              }
              return LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}

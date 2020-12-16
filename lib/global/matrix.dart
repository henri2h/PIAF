import 'dart:developer' as developer;
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/utils/fameldysdk_store.dart';

class Matrix extends StatefulWidget {
  final Widget child;

  Matrix({Key key, this.child}) : super(key: key);

  @override
  MatrixState createState() => MatrixState();

  /// Returns the (nearest) Client instance of your application.
  static MatrixState of(BuildContext context) {
    var newState =
        (context.dependOnInheritedWidgetOfExactType<_InheritedMatrix>()).data;
    newState.context = context;
    return newState;
  }
}

class MatrixState extends State<Matrix> {
  Client client;
  SMatrix sclient;
  @override
  BuildContext context;

  @deprecated
  Future<void> connect() async {
    client.onLoginStateChanged.stream.listen((LoginState loginState) {
      print("LoginState: ${loginState.toString()}");
    });
  }

  @override
  void initState() {
    print("Init state...");
    super.initState();
    initMatrix();
  }

  void initMatrix() {
    String clientName = "minestrix";
    client = Client(clientName, databaseBuilder: getDatabase);
    print("Matrix state initialisated");
    _initWithStore();
  }

  void _initWithStore() async {
    var initLoginState = client.onLoginStateChanged.stream.first;
    try {
      client.init();

      final firstLoginState = await initLoginState;
      if (firstLoginState == LoginState.logged) {
        print("Logged in");

        sclient = SMatrix(client);
        await sclient.init();
      } else {
        print("Not logged in");

        /*await Matrix.of(context)
            .client
            .requestThirdPartyIdentifiers()
            .then((l) {
          if (l.isEmpty) {
            print(l);
          } else {
            print("empty");
          }
        });*/
      }
    } catch (e) {
      print(e);
      print("error");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("build");
    return _InheritedMatrix(data: this, child: widget.child);
  }
}

class _InheritedMatrix extends InheritedWidget {
  final MatrixState data;

  _InheritedMatrix({Key key, this.data, Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedMatrix old) {
    var update = old.data.client.accessToken != data.client.accessToken ||
        old.data.client.userID != data.client.userID ||
        old.data.client.deviceID != data.client.deviceID ||
        old.data.client.deviceName != data.client.deviceName ||
        old.data.client.homeserver != data.client.homeserver;
    return update;
  }
}

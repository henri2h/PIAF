import 'dart:async';
import 'dart:developer' as developer;
import 'package:famedlysdk/encryption/utils/key_verification.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/components/keyVerificationDialog.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/utils/fameldysdk_store.dart';
import 'package:minestrix/utils/platforms_info.dart';

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

  StreamSubscription<KeyVerification> onKeyVerificationRequestSub;

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
    final Set verificationMethods = <KeyVerificationMethod>{
      KeyVerificationMethod.numbers
    };

    if (PlatformInfos.isMobile) {
      // emojis don't show in web somehow
      verificationMethods.add(KeyVerificationMethod.emoji);
    }
    
    String clientName = "minestrix";
    client = Client(clientName,
    enableE2eeRecovery: true,
        verificationMethods: verificationMethods, databaseBuilder: getDatabase);

    onKeyVerificationRequestSub ??= client.onKeyVerificationRequest.stream
        .listen((KeyVerification request) async {
      print("KeyVerification");
      print(request.deviceId);
      print(request.isDone);

       var hidPopup = false;
      request.onUpdate = () {
        if (!hidPopup &&
            {KeyVerificationState.done, KeyVerificationState.error}
                .contains(request.state)) {
          Navigator.of(context, rootNavigator: true).pop('dialog');
        }
        hidPopup = true;
      };


      /*if (await showOkCancelAlertDialog(
            context: context,
            title: L10n.of(context).newVerificationRequest,
            message: L10n.of(context).askVerificationRequest(request.userId),
          ) ==
          OkCancelResult.ok) {*/
        request.onUpdate = null;
        hidPopup = true;
        await request.acceptVerification();
        await KeyVerificationDialog(request: request).show(context);
     /* } else {
        request.onUpdate = null;
        hidPopup = true;
        await request.rejectVerification();
      }*/
    });
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

        print(client.deviceID);
        print(client.deviceName);

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
  void dispose() {
    onKeyVerificationRequestSub?.cancel();
    super.dispose();
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

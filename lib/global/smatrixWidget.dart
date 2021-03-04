import 'dart:async';
import 'package:famedlysdk/encryption/utils/key_verification.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/components/dialogs/keyVerificationDialog.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
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
  SClient sclient;
  @override
  BuildContext context;

  StreamSubscription<KeyVerification> onKeyVerificationRequestSub;
  StreamSubscription<EventUpdate> onEvent;

  @deprecated
  Future<void> connect() async {
    sclient.onLoginStateChanged.stream.listen((LoginState loginState) {
      print("LoginState: ${loginState.toString()}");
    });
  }

  @override
  void initState() {
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
    sclient = SClient(clientName,
        enableE2eeRecovery: true,
        verificationMethods: verificationMethods,
        databaseBuilder: getDatabase);

    onKeyVerificationRequestSub ??= sclient.onKeyVerificationRequest.stream
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
    onEvent ??= sclient.onEvent.stream
        .where((event) =>
            [EventTypes.Message, EventTypes.Encrypted]
                .contains(event.eventType) &&
            event.content['sender'] != sclient.userID)
        .listen((EventUpdate eventUpdate) async {
      // we should react differently depending on wether the event is a smatrix one or not...
      Room room = sclient.getRoomById(eventUpdate.roomID);
      Event event = Event.fromJson(eventUpdate.content, room);

      // don't throw a notification for old events
      if (event.originServerTs
              .compareTo(DateTime.now().subtract(Duration(seconds: 5))) >
          0)
      // check if it is a message
      if (SMatrixRoom.getSRoomType(room) != null) {
        Profile profile = await sclient.getUserFromRoom(room);
        Flushbar(
          title: "New post from " + profile.displayname,
          message: event.body,
          duration: Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
        )..show(context);
      } else {
        Flushbar(
          title: event.sender.displayName + "@" + room.name,
          message: event.body,
          duration: Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
        )..show(context);
      }
    });

    print("Matrix state initialisated");
    _initWithStore();
  }

  void _initWithStore() async {
    var initLoginState = sclient.onLoginStateChanged.stream.first;
    try {
      sclient.init();

      final firstLoginState = await initLoginState;
      if (firstLoginState == LoginState.logged) {
        await sclient.initSMatrix();
      } else {
        print("Not logged in");
      }
    } catch (e) {
      print(e);
      print("error : Could not initWithStore");
    }
  }

  @override
  void dispose() {
    onKeyVerificationRequestSub?.cancel();
    onEvent?.cancel();
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
    var update = old.data.sclient.accessToken != data.sclient.accessToken ||
        old.data.sclient.userID != data.sclient.userID ||
        old.data.sclient.deviceID != data.sclient.deviceID ||
        old.data.sclient.deviceName != data.sclient.deviceName ||
        old.data.sclient.homeserver != data.sclient.homeserver;
    return update;
  }
}

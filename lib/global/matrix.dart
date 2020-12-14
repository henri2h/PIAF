import 'dart:developer' as developer;
import 'package:famedlysdk/famedlysdk.dart';

class MatrixClient {
  Client client = Client("Minetrix");
  MatrixClient() {
    developer.log("Lets's start", name: 'minetrix.matrixclient');
  }

  Future<void> connect() async {
    client.onLoginStateChanged.stream.listen((LoginState loginState) {
      print("LoginState: ${loginState.toString()}");
    });

    client.onEvent.stream.listen((EventUpdate eventUpdate) {
      print("New event update!");
    });

    client.onRoomUpdate.stream.listen((RoomUpdate eventUpdate) {
      print("New room update!");
    });

    try {
      await client.checkHomeserver("");
      await client.login(user: "", password: "");
    } catch (e) {
      print('No luck...');
    }
  }
}

import 'package:matrix/matrix.dart';

extension EventLocalisationExtension on Event {
  String get senderLocalisedDisplayName {
    return senderId == room.client.userID
        ? const MatrixDefaultLocalizations().you
        : (sender.calcDisplayname());
  }
}

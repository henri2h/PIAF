import 'package:matrix/matrix.dart';

extension TimelineExtension on Timeline {
  List<Event> getImages() {
    return events
        .where((event) =>
            event.type == EventTypes.Message &&
            event.messageType == MessageTypes.Image &&
            event.redacted == false)
        .toList();
  }
}

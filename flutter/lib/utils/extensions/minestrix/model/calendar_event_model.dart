import 'package:matrix/matrix.dart';

const String eventStartKey = "event_start";
const String eventEndKey = "event_end";
const String eventPollIdKey = "event_poll_id";
const String eventPlaceKey = "event_place";

class CalendarEvent {
  Event? e;

  String? pollId;
  String? place;
  DateTime? start;
  DateTime? end;

  CalendarEvent();

  CalendarEvent.fromEvent(Event event) : e = event {
    final startInt = int.tryParse(e!.content[eventStartKey].toString());
    final endInt = int.tryParse(e!.content[eventEndKey].toString());

    start = startInt != null
        ? DateTime.fromMillisecondsSinceEpoch(startInt)
        : DateTime.now();
    end = endInt != null
        ? DateTime.fromMillisecondsSinceEpoch(endInt)
        : DateTime.now();

    pollId = e!.content.tryGet<String>(eventPollIdKey);
    place = e!.content.tryGet<String>(eventPlaceKey);
  }

  /// Get the event's duration with a minute accuracy.
  /// If the event's duration is negative, then the function will return 0.
  Duration get duration {
    if (start == null) {
      return Duration.zero;
    }

    return Duration(minutes: end?.difference(start!).inMinutes ?? 0);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (pollId != null) data[eventPollIdKey] = pollId;
    if (place != null) data[eventPlaceKey] = place;
    if (start != null) data[eventStartKey] = start!.millisecondsSinceEpoch;
    if (end != null) data[eventEndKey] = end!.millisecondsSinceEpoch;

    return data;
  }
}

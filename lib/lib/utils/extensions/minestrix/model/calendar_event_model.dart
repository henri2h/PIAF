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
    start = e!.content.containsKey(eventStartKey)
        ? DateTime.fromMillisecondsSinceEpoch(e!.content[eventStartKey])
        : DateTime.now();
    end = e!.content.containsKey(eventEndKey)
        ? DateTime.fromMillisecondsSinceEpoch(e!.content[eventEndKey])
        : DateTime.now();

    pollId = e!.content.tryGet<String>(eventPollIdKey);
    place = e!.content.tryGet<String>(eventPlaceKey);
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

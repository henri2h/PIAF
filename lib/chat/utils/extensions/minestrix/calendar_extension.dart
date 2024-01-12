import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/config/matrix_types.dart';
import 'package:minestrix/chat/utils/extensible_event/extensible_event_content.dart';
import 'package:minestrix/chat/utils/extensions/matrix/client_extension.dart';
import 'package:minestrix/chat/utils/poll/json/event_poll_start.dart';
import 'package:minestrix/chat/utils/poll/poll.dart';

import 'model/calendar_event_model.dart';

extension CalendarExtension on Client {
  List<Room> get calendarEvents =>
      filterRoomWithType(MatrixTypes.calendarEvent).toList();

  /// Create the matrix event room
  Future<Room?> createCalendarEventRoom(Client c,
      {required String name, required String topic, Room? parentSpace}) async {
    String roomId = await createRoom(
      creationContent: {"type": MatrixTypes.calendarEvent},
      name: name,
      topic: topic,
    );

    await waitForRoomInSync(roomId);

    Room? r = c.getRoomById(roomId);
    if (r != null) {
      // Add attendance form
      await r.setPollAttendance(CalendarEvent());

      return r;
    }
    return null;
  }
}

extension CalendarRoomExtension on Room {
  /// Send the poll to get the attendance and update the poll attendance state
  Future<String?> setPollAttendance(CalendarEvent e) async {
    EventPollStart pollAttendance = EventPollStart();
    pollAttendance.kind = PollKindEnum.disclosed;
    pollAttendance.answers = [
      PollAnswer()
        ..id = CalendarAttendanceResponses.going
        ..text = "Going",
      PollAnswer()
        ..id = CalendarAttendanceResponses.interested
        ..text = "Interested",
      PollAnswer()
        ..id = CalendarAttendanceResponses.declined
        ..text = "Declined"
    ];

    pollAttendance.question = ExtensibleEventContent()..text = "Viens tu ?";
    pollAttendance.maxSelections = 1;

    String? eventId = await Poll.sendPollStart(this, pollAttendance);

    if (eventId != null) {
      e.pollId = eventId;
      return await sendCalendarEventState(e);
    }
    return null;
  }

  Future<String> sendCalendarEventState(CalendarEvent e) async {
    return await client.setRoomStateWithKey(
        id, MatrixStateTypes.calendarEventPollAttendance, "", e.toJson());
  }

  /// Try to get the poll attendance event from the timeline or the server
  CalendarEvent? getEventAttendanceEvent() {
    Event? event = getState(MatrixStateTypes.calendarEventPollAttendance);
    return event != null ? CalendarEvent.fromEvent(event) : null;
  }
}

/// Event attendance responses
abstract class CalendarAttendanceResponses {
  static const String going = "going";
  static const String interested = "interested";
  static const String declined = "declined";
}

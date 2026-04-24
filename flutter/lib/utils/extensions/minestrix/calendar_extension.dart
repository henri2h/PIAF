import 'package:matrix/matrix.dart';
import 'package:piaf/utils/extensions/matrix/client_extension.dart';

import '../../../config/matrix_types.dart';
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
    var room = e.e?.room;

    var eventId = await room?.startPoll(
        question: "Coming?",
        answers: [
          PollAnswer(id: CalendarAttendanceResponses.going, mText: "Going"),
          PollAnswer(
              id: CalendarAttendanceResponses.interested, mText: "Interested"),
          PollAnswer(
              id: CalendarAttendanceResponses.declined, mText: "Declined")
        ],
        maxSelections: 1);

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
    StrippedStateEvent? event =
        getState(MatrixStateTypes.calendarEventPollAttendance);
    return event is Event ? CalendarEvent.fromEvent(event) : null;
  }
}

/// Event attendance responses
abstract class CalendarAttendanceResponses {
  static const String going = "going";
  static const String interested = "interested";
  static const String declined = "declined";
}

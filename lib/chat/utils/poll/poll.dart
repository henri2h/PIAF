import 'package:matrix/matrix.dart';

import 'package:piaf/chat/config/matrix_types.dart';
import 'package:piaf/chat/config/relationship_types.dart' as rel;
import 'package:piaf/chat/utils/poll/json/event_poll_response.dart';
import 'package:piaf/chat/utils/poll/json/event_poll_start.dart';

/// A class to provide the logic to interact with polls
class Poll {
  Event e;
  Timeline t;

  EventPollResponse? get userResponse => responses[e.room.client.userID] != null
      ? EventPollResponse.fromEvent(responses[e.room.client.userID]!)
      : null;

  EventPollStart get poll => EventPollStart.fromEvent(e);

  Set<Event> get references =>
      e.aggregatedEvents(t, rel.RelationshipTypes.reference);

  /// Get the responses form the user. We return a map to be sure that each user is counted only one time
  Map<String, Event> get responses {
    Iterable<Event> events = references
        .where((event) => event.type == MatrixEventTypes.pollResponse);
    Map<String, Event> eventsMap = {};
    for (Event e in events) {
      eventsMap[e.senderId] = e;
    }
    return eventsMap;
  }

  bool get isEnded => references
      .where((event) => (event.type == MatrixEventTypes.pollEnd &&
          event.senderId == e.senderId))
      .isNotEmpty;

  Map<String, int> get responsesMap {
    Map<String, int> resp = {};

    for (Event respEvent in responses.values) {
      EventPollResponse res = EventPollResponse.fromEvent(respEvent);

      for (String answer in res.answers ?? []) {
        resp[answer] = (resp[answer] ?? 0) + 1;
      }
    }
    return resp;
  }

  Poll({required this.e, required this.t});

  Future<void> answer(String? value) async {
    EventPollResponse res = EventPollResponse();
    res.answers = [if (value != null) value];

    Map<String, dynamic> responseMap = {
      MatrixEventTypes.pollResponse: res.toJson(),
      'm.relates_to': {
        'event_id': e.eventId,
        'rel_type': rel.RelationshipTypes.reference,
      }
    };
    await e.room.sendEvent(responseMap, type: MatrixEventTypes.pollResponse);
  }

  static Future<String?> sendPollStart(Room r, EventPollStart poll) async {
    return await r.sendEvent({MatrixEventTypes.pollStart: poll.toJson()},
        type: MatrixEventTypes.pollStart);
  }
}

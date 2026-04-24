import 'package:matrix/matrix.dart';

extension MatrixEventExension on Event {
  /// Fetches the event to be rendered, taking into account all the edits and the like.
  /// It needs a [timeline] for that.

  Event getDisplayEventWithType(Timeline timeline, String type) {
    if (redacted) {
      return this;
    }
    if (hasAggregatedEvents(timeline, RelationshipTypes.edit)) {
      // alright, we have an edit
      final allEditEvents = aggregatedEvents(timeline, RelationshipTypes.edit)
          // we only allow edits made by the original author themself
          .where((e) => e.senderId == senderId && e.type == type)
          .toList();
      // we need to check again if it isn't empty, as we potentially removed all
      // aggregated edits
      if (allEditEvents.isNotEmpty) {
        allEditEvents.sort((a, b) => a.originServerTs.millisecondsSinceEpoch -
                    b.originServerTs.millisecondsSinceEpoch >
                0
            ? 1
            : -1);
        final rawEvent = allEditEvents.last.toJson();
        // update the content of the new event to render
        if (rawEvent['content']['m.new_content'] is Map) {
          rawEvent['content'] = rawEvent['content']['m.new_content'];
        }
        return Event.fromJson(rawEvent, room);
      }
    }
    return this;
  }

  String? get emoji =>
      content.tryGetMap<String, dynamic>('m.relates_to')?.tryGet<String>('key');

  bool get sentByUser => senderId == room.client.userID;
}

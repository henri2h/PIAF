import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:piaf/utils/extensions/matrix/room_initialsync_extension.dart';

extension PeekingExtension on Client {
  Future<Timeline> peekRoom(String roomId) async {
    final response = await initialSync(
      roomId,
    );

    final room = Room(id: roomId, client: this);
    room.prev_batch = response.messages?.end;

    // to prevent storing events in the database
    room.membership = Membership.leave;

    final timeline = Timeline(
        room: room,
        chunk: TimelineChunk(
            events: response.messages?.chunk?.reversed
                    .toList() // we display the event in the other sence
                    .map((e) => Event.fromMatrixEvent(e, room))
                    .toList() ??
                []));

    // Apply states
    response.state?.forEach((event) {
      room.setState(Event.fromMatrixEvent(
        event,
        room,
      ));
    });

    for (var event in response.messages?.chunk ?? []) {
      room.setState(Event.fromMatrixEvent(
        event,
        room,
      ));
    }

    return timeline;
  }
}

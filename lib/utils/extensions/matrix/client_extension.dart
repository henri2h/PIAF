import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';

import '../../../features/chat/widgets/chat_page_items/provider/chat_page_state.dart';

extension ClientExtension on Client {
  Iterable<Room> filterRoomWithType(String type) {
    List<Room> r = rooms.where((r) => r.type == type).toList();
    return r;
  }

  int get chatNotificationsCount {
    int count = 0;

    for (var room in rooms) {
      if (!ChatPageState.ignoredRoomTypes.contains(room.type)) {
        final roomCount = room.notificationCount;
        if (roomCount == 0 && room.isUnreadOrInvited) {
          count += 1;
        } else {
          count += roomCount;
        }
      }
    }
    return count;
  }

  Future<void> waitForRoomInSync(String roomId) async {
    await onRoomInSync(roomId).first;
  }

  Stream<SyncUpdate> onRoomInSync(String roomId,
      {bool join = false, bool invite = false, bool leave = false}) {
    if (!join && !invite && !leave) {
      join = true;
      invite = true;
      leave = true;
    }

    return onSync.stream.where((sync) =>
        invite && (sync.rooms?.invite?.containsKey(roomId) ?? false) ||
        join && (sync.rooms?.join?.containsKey(roomId) ?? false) ||
        leave && (sync.rooms?.leave?.containsKey(roomId) ?? false));
  }

  Iterable<Room> get spaces => rooms.where((Room r) => r.isSpace);

  /// Searches for the event in the local cache and then on the server if not
  /// found. Returns null if not found anywhere.
  Future<Event?> getEventFromArbitraryRoomById(
      String eventID, String roomID) async {
    final room = getRoomById(roomID);
    if (room != null) {
      final dbEvent = await database?.getEventById(eventID, room);
      if (dbEvent != null) return dbEvent;
    }
    final matrixEvent = await getOneRoomEvent(roomID, eventID);
    final event =
        Event.fromMatrixEvent(matrixEvent, Room(client: this, id: roomID));
    if (event.type == EventTypes.Encrypted && encryptionEnabled) {
      // attempt decryption
      return await encryption?.decryptRoomEvent(event, store: false);
    }
    return event;
  }
}

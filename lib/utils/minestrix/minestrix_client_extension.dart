import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/utils/room_feed_extension.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

extension MinestrixClientExtension on Client {
  List<Room> get srooms => rooms.where((r) => r.isFeed).toList();

  /// Return a map of all the user feed room for each user
  Map<String, List<Room>> get sroomsByUserId {
    Map<String, List<Room>> _srooms = {};

    for (var i = 0; i < rooms.length; i++) {
      Room r = rooms[i];
      if (r.isFeed && r.feedType == FeedRoomType.user) {
        print("feed: ${r.name} ${r.creatorId}");

        if (_srooms[r.creatorId ?? ''] == null) {
          _srooms[r.creatorId ?? ''] = [r];
        } else {
          _srooms[r.creatorId ?? '']!.add(r);
        }
      }
    }
    return _srooms;
  }

  // room sub types
  List<Room> get sgroups =>
      srooms.where((room) => room.feedType == FeedRoomType.group).toList();

  List<Room> get sfriends =>
      srooms.where((room) => room.feedType == FeedRoomType.user).toList();

  List<Room> get following =>
      srooms.where((room) => room.feedType == FeedRoomType.user).toList();

  List<Room> get minestrixInvites => srooms
      .where((room) => room.membership == Membership.invite)
      .toList(); // friends requests*/

  List<Room> get minestrixUserRoom =>
      srooms.where((r) => r.creatorId == userID).toList();

  bool get userRoomCreated => minestrixUserRoom.length > 0;

  Future<String> createMinestrixAccount(String name, String desc,
      {bool waitForCreation = true,
      Visibility visibility = Visibility.private}) async {
    String roomID = await createRoom(
        name: name,
        topic: desc,
        visibility: visibility,
        creationContent: {"type": MatrixTypes.account});
    if (waitForCreation) {
      // Wait for room actually appears in sync and update all
      await onSync.stream
          .firstWhere((sync) => sync.rooms?.join?.containsKey(roomID) ?? false);
    }

    return roomID;
  }

  Future<void> createSMatrixUserProfile() async {
    String name = userID! + " timeline";
    await createMinestrixAccount(name, "Private MinesTRIX profile",
        waitForCreation: true);
  }

  Future<String> createMinestrixGroup(String name, String desc,
      {waitForCreation = true,
      Visibility visibility = Visibility.private}) async {
    String roomID = await createRoom(
        name: name,
        topic: desc,
        visibility: Visibility.private,
        creationContent: {"type": MatrixTypes.group});

    if (waitForCreation) {
      // Wait for room actually appears in sync
      await onSync.stream
          .firstWhere((sync) => sync.rooms?.join?.containsKey(roomID) ?? false);
    }

    return roomID;
  }

  Future<bool> inviteFriend(String userId,
      {Room? r, bool waitForInvite = true}) async {
    if (r == null) {
      r = minestrixUserRoom.firstOrNull;
    }

    if (r != null) {
      await r.invite(userId);
      if (waitForInvite) {
        // Wait for room actually appears in sync
        await onSync.stream.firstWhere(
            (sync) => sync.rooms?.join?.containsKey(r?.id) ?? false);
      }
      return true;
    }
    return false; // we haven't been able to add this user to our friend list
  }

  Iterable<Event> getSRoomFilteredEvents(Timeline t,
      {List<String> eventTypesFilter: const [
        MatrixTypes.post,
        EventTypes.Encrypted
      ]}) {
    List<Event> filteredEvents = t.events
        .where((e) =>
            !{
              RelationshipTypes.edit,
              RelationshipTypes.reaction,
              RelationshipTypes.reply,
              MatrixTypes.threadRelation
            }.contains(e.relationshipType) &&
            eventTypesFilter.contains(e.type) &&
            !e.redacted)
        .toList();
    for (var i = 0; i < filteredEvents.length; i++) {
      filteredEvents[i] = filteredEvents[i].getDisplayEvent(t);
    }
    return filteredEvents;
  }

  Iterable<Event> getPostReactions(Iterable<Event> events) => events
      .where((e) =>
          {MatrixTypes.threadRelation}.contains(e.relationshipType) &&
          [MatrixTypes.post, EventTypes.Message, EventTypes.Encrypted]
              .contains(e.type) &&
          !e.redacted)
      .toList();

  Future<List<Event>> getMinestrixEvents() async {
    List<Event> events = [];

    for (Room room in srooms) {
      Timeline t = await room.getTimeline();
      final filteredEvents = getSRoomFilteredEvents(t);
      events.addAll(filteredEvents);
    }

    return events;
  }
}

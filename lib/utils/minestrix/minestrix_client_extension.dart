import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/config/matrix_types.dart';
import 'package:minestrix_chat/utils/matrix/power_levels_extension.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/utils/social/posts/posts_event_extension.dart';

extension MinestrixClientExtension on Client {
  List<Room> get srooms => rooms.where((r) => r.isFeed).toList();

  /// Return a map of all the user feed room for each user
  Map<String, List<Room>> get sroomsByUserId {
    Map<String, List<Room>> _srooms = {};

    for (var i = 0; i < rooms.length; i++) {
      Room r = rooms[i];
      if (r.isFeed && r.feedType == FeedRoomType.user) {
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

  Future<String> createPrivateMinestrixProfile() async {
    final p = await getProfileFromUserId(userID!);
    return await createMinestrixAccount(
        "${p.displayName ?? userID!}'s private timeline", "",
        public: false);
  }

  Future<String> createPublicMinestrixProfile() async {
    final p = await getProfileFromUserId(userID!);
    return await createMinestrixAccount(
        "${p.displayName ?? userID!}'s public timeline", "",
        public: true);
  }

  Future<String> createMinestrixAccount(String name, String desc,
      {bool waitForCreation = true, bool public = true}) async {
    String roomID = await createRoom(
        name: name,
        topic: desc,
        preset:
            public ? CreateRoomPreset.publicChat : CreateRoomPreset.privateChat,
        creationContent: {"type": MatrixTypes.account});
    if (waitForCreation) {
      // Wait for room actually appears in sync and update all
      await onSync.stream
          .firstWhere((sync) => sync.rooms?.join?.containsKey(roomID) ?? false);
    }

    final room = getRoomById(roomID);
    if (room != null) {
      if (!public) {
        await room.setJoinRules(JoinRules.knock);
        await room.setPowerLevels({"invite": 50});
      } else {
        await room.setJoinRules(JoinRules.public);
        await room.setHistoryVisibility(HistoryVisibility.shared);
      }
    }

    return roomID;
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
    r ??= minestrixUserRoom.firstOrNull;

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
          ]}) =>
      t.room.getPosts(t, eventTypesFilter: eventTypesFilter);

  Iterable<Event> getPostReactions(Iterable<Event> events) => events
      .where((e) =>
          [
            MatrixTypes.post,
            MatrixTypes.comment,
            EventTypes.Message,
            EventTypes.Encrypted
          ].contains(e.type) &&
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

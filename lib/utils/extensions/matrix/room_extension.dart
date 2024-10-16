import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';

import '../../../config/matrix_types.dart';

extension RoomExtension on Room {
  StrippedStateEvent? get stateRoomCreate => getState(EventTypes.RoomCreate);
  StrippedStateEvent? get stateRoomtype => getState("m.room.type");
  StrippedStateEvent? get stateRoomTopic => getState(EventTypes.RoomTopic);
  StrippedStateEvent? get stateRoomBridgeInfo => getState(EventTypes.RoomTopic);

  User? get creator {
    final event = stateRoomCreate;
    if (event is Event) return event.senderFromMemoryOrFallback;
    return null;
  }

  String? get creatorId => stateRoomCreate?.senderId;

  String get type => stateRoomCreate?.content.tryGet<String>('type') ?? '';
  String? get subtype => stateRoomtype?.content.tryGet<String>('type');

  bool get isLowPriority => tags.containsKey(TagType.lowPriority);
  Future<void> setLowPriority(bool lowPriority) => lowPriority
      ? addTag(TagType.lowPriority)
      : removeTag(TagType.lowPriority);

  Stream<SyncUpdate> onRoomInSync(
          {bool join = false, bool invite = false, bool leave = false}) =>
      client.onRoomInSync(id, join: join, invite: invite, leave: leave);

  Future<void> waitForRoomSync() async => await onRoomInSync().first;

  Event? getEventFromState(String type) {
    final event = getState(type);
    if (event is Event) return event;
    return null;
  }
}

extension RoomFeedExtension on Room {
  String get feedName {
    if (feedType == FeedRoomType.user) {
      return creator?.displayName ?? creatorId ?? 'null';
    } else {
      return name;
    }
  }

  Uri? get feedAvatar =>
      feedType == FeedRoomType.user ? creator?.avatarUrl : avatar;

  bool get isUserPage => creatorId == client.userID;

  FeedRoomType? get feedType {
    switch (type) {
      case MatrixTypes.account:
        return FeedRoomType.user;
      case MatrixTypes.group:
        return FeedRoomType.group;
      case MatrixTypes.calendarEvent:
        return FeedRoomType.calendar;
      default:
    }
    return null;
  }

  bool get isFeed => feedType != null;
}

enum FeedRoomType { user, group, calendar }

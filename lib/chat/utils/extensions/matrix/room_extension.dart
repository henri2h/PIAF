import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';

import '../../../config/matrix_types.dart';

extension RoomExtension on Room {
  Event? get createEvent => getState(EventTypes.RoomCreate);
  User? get creator => createEvent?.senderFromMemoryOrFallback;
  String? get creatorId => createEvent?.senderId;
  String get type => createEvent?.content.tryGet<String>('type') ?? '';

  Event? get typeEvent => getState("m.room.type");
  String? get subtype => typeEvent?.content.tryGet<String>('type');

  bool get isLowPriority => tags.containsKey(TagType.lowPriority);
  Future<void> setLowPriority(bool lowPriority) => lowPriority
      ? addTag(TagType.lowPriority)
      : removeTag(TagType.lowPriority);

  Stream<SyncUpdate> onRoomInSync(
          {bool join = false, bool invite = false, bool leave = false}) =>
      client.onRoomInSync(id, join: join, invite: invite, leave: leave);

  Future<void> waitForRoomSync() async => await onRoomInSync().first;
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

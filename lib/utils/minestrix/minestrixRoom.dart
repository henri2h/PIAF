import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/room_feed_extension.dart';

class MinestrixRoom {
  final Room room;

  Timeline? timeline;

  MinestrixRoom(Room r) : room = r;

  String get name => room.feedName;
  Uri? get avatar => room.feedAvatar;

  FeedRoomType? get type => room.feedType;

  User? get user => room.creator;
  String? get userID => room.creatorId;
}

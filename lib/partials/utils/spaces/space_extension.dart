import 'package:matrix/matrix.dart';
import 'package:piaf/partials/minestrix_chat.dart';

/// Small class to contain a room and/or the space result

class RoomWithSpace {
  Room? room;
  SpaceRoomsChunk? space;

  /// Save the creator of the room in the case where we only have the space result
  String? _creator;

  String get id => room?.id ?? space!.roomId;
  String get displayname =>
      room?.getLocalizedDisplayname() ?? space?.name ?? '';
  String get topic => room?.topic ?? space?.topic ?? '';
  String? get creatorId => room?.creatorId ?? _creator;

  Uri? get avatar => room?.avatar;

  RoomWithSpace({this.room, this.space, String? creator}) {
    _creator = creator;
  }
}

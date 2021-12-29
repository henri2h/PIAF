import 'package:logging/logging.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixTypes.dart';

class MinestrixRoom {
  static final log = Logger("MinestrixRoom");

  // would have liked to extends Room type, but couldn't manage to get Down Casting to work properly...
  // initialize the class, return false, if it could not generate the classes
  // i.e, it is not a valid class

  // final variable
  late User user;
  late Room room;
  SRoomType? roomType = SRoomType.UserRoom; // by default

  Timeline? timeline;
  bool _validSRoom = false;
  bool get validSRoom => _validSRoom;

  String get name {
    if (roomType == SRoomType.UserRoom)
      return user.displayName ?? user.id;
    else {
      return room.name;
    }
  }

  String get userID => user.id;

  Uri? get avatar =>
      roomType == SRoomType.UserRoom ? user.avatarUrl : room.avatar;

  bool get isUserPage => user.id == room.client.userID;

  void loadRoomCreator(MinestrixClient sclient) async {
    Event? state = room.getState("m.room.create");
    User? u = state?.sender;
    assert(u != null);
    user = u!;
  }

  static MinestrixRoom? loadMinesTrixRoom(Room r, MinestrixClient sclient) {
    try {
      MinestrixRoom sr = MinestrixRoom();

      // initialise room
      sr.room = r;
      sr.roomType = getSRoomType(r);
      if (sr.roomType == null) return null;

      sr.loadRoomCreator(sclient);

      if (sr.roomType == SRoomType.UserRoom) {
        sr._validSRoom = true;
        return sr;
      } else if (sr.roomType == SRoomType.Group) {
        sr._validSRoom = true;
        return sr;
      }
    } catch (_) {}
    return null;
  }

  static User? findUser(List<User> users, String? userId) {
    try {
      return users.firstWhere((User u) => userId == u.id);
    } catch (e) {
      // return null if no element
      print("Could not find user : " + (userId ?? 'null') + " " + e.toString());
    }
    return null;
  }

  static SRoomType? getSRoomType(Room room) {
    Event? state = room.getState("m.room.create");

    if (state != null && state.content["type"] != null) {
      // check if it is a group or account room if not, throw null
      if (state.content["type"] == MinestrixTypes.account)
        return SRoomType.UserRoom;
      else if (state.content["type"] == MinestrixTypes.group)
        return SRoomType.Group;
    }

    return null;
  }
}

enum SRoomType { UserRoom, Group }

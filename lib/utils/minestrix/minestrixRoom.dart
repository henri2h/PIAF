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

  String? get name {
    if (roomType == SRoomType.UserRoom)
      return user.displayName;
    else {
      return room.name;
    }
  }

  Future<void> loadRoomCreator(MinestrixClient sclient) async {
    Event? state = room.getState("m.room.create");

    if (state != null) {
      // get creator id from cache and if not in cache, from server
      String? creatorID = state.content["creator"];

      assert(creatorID != null);

      // find local on local users
      List<User> users = room.getParticipants();
      User? u = findUser(users, creatorID);

      if (u == null) {
        users = await room.requestParticipants();
        u = findUser(users, creatorID);
      }

      // TODO : check if needed
      if (u == null) {
        if (room.membership == Membership.invite) {
          // in the case we can't request participants

          Profile p = await sclient.getProfileFromUserId(creatorID!);
          u = User(creatorID,
              membership: "m.join",
              avatarUrl: p.avatarUrl.toString(),
              displayName: p.displayName,
              room: room);
        }
      }

      assert(u != null);
      user = u!; // save the discovered user
    }
  }

  static Future<MinestrixRoom?> loadMinesTrixRoom(
      Room r, MinestrixClient sclient) async {
    try {
      MinestrixRoom sr = MinestrixRoom();

      // initialise room
      sr.room = r;
      sr.roomType = await getSRoomType(r);
      if (sr.roomType == null) return null;

      await sr.loadRoomCreator(sclient);

      if (sr.roomType == SRoomType.UserRoom) {
        sr._validSRoom = true;
        return sr;
      } else if (sr.roomType == SRoomType.Group) {
        sr._validSRoom = true;
        return sr;
      }
    } catch (e) {
      log.severe("Could not load room", e);
    }
    return null;
  }

  static User? findUser(List<User> users, String? userId) {
    try {
      return users.firstWhere((User u) => userId == u.id);
    } catch (e) {
      // return null if no element
      log.severe("Could not find user : " + (userId ?? 'null'), e);
    }
    return null;
  }

  static Future<SRoomType?> getSRoomType(Room room) async {
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

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

  Uri? get avatar =>
      roomType == SRoomType.UserRoom ? user.avatarUrl : room.avatar;

  Future<void> loadRoomCreator(MinestrixClient sclient) async {
    Event? state = room.getState("m.room.create");

    if (state != null) {
      // get creator id from cache and if not in cache, from server
      String? creatorID = state.content["creator"];

      assert(creatorID != null);
      User? u;

      if (room.membership != Membership.invite ||
          room.historyVisibility == HistoryVisibility.worldReadable) {
        // find local on local users
        List<User> users = room.getParticipants();
        u = findUser(users, creatorID);

        if (u == null) {
          // we have not found the user but maybe we just can't preview the room
          users = await room.requestParticipants();
          u = findUser(users, creatorID);
        }
      } else if (u == null) {
        // in the case we can't request participants

        Profile p = await sclient.getProfileFromUserId(creatorID!);
        u = User(creatorID,
            membership: "m.join",
            avatarUrl: p.avatarUrl.toString(),
            displayName: p.displayName,
            room: room);
      }

      assert(u !=
          null); // if we could not find the creator of the room in the members of the room. It could mean that the user creator has left the room. We should not consider it as valid.
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

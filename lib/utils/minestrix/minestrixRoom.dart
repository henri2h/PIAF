import 'package:logging/logging.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixTypes.dart';

class MinestrixRoom {
  final log = Logger("SMatrixRoom");

  // would have liked to extends Room type, but couldn't manage to get Down Casting to work properly...
  // initialize the class, return false, if it could not generate the classes
  // i.e, it is not a valid class

  // final variable
  User? user;
  Room? room;
  SRoomType? roomType = SRoomType.UserRoom; // by default

  Timeline? timeline;
  bool _validSRoom = false;
  bool get validSRoom => _validSRoom;

  String? get name {
    if (roomType == SRoomType.UserRoom)
      return user!.displayName;
    else {
      return room!.name;
    }
  }

  Future<void> loadRoomCreator(MinestrixClient sclient) async {
    Event? state = room!.getState("m.room.create");

    if (state != null) {
      // get creator id from cache and if not in cache, from server
      String? creatorID = state.content["creator"];

      // find local on local users
      List<User> users = room!.getParticipants();
      user = findUser(users, creatorID);

      try {
        if (user == null) {
          users = await room!.requestParticipants();
          user = findUser(users, creatorID);
        }
      } catch (e) {
        log.severe("Could not request participants", e);
        print("Creator userID : " + creatorID!);
      }
    }
  }

  static Future<MinestrixRoom?> loadMinesTrixRoom(Room r, MinestrixClient sclient) async {
    try {
      MinestrixRoom sr = MinestrixRoom();
      sr.roomType = await getSRoomType(r);

      if (sr.roomType != null) {
        sr.room = r;

        await sr.loadRoomCreator(sclient);

        print(sr.name! + " : " + sr.user!.displayName!);

        if (sr.roomType == SRoomType.UserRoom) {
          String userId = MinestrixClient.getUserIdFromRoomName(sr.room!.name);

          if (sr.user != null) {
            sr._validSRoom = true;
            return sr;
          }

          if (r.membership == Membership.invite) {
            // in the case we can't request participants
            if (sr.user == null) {
              Profile p = await sclient.getProfileFromUserId(userId);
              sr.user = User(userId,
                  membership: "m.join",
                  avatarUrl: p.avatarUrl.toString(),
                  displayName: p.displayName,
                  room: r);
            }
            return sr; // we cannot yet access to the room participants
          }

          print("issue, not a smatrix room : " + r.name);
        } else if (sr.roomType == SRoomType.Group) {
          return sr;
        }
      }
    } catch (e) {
      print("Error in loading room " + e.toString());
      //log.severe("Could not init smatrix client", e);
    }
    return null;
  }

  static User? findUser(List<User> users, String? userId) {
    try {
      return users.firstWhere((User u) => userId == u.id);
    } catch (_) {
      // return null if no element

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

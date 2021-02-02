import 'package:famedlysdk/famedlysdk.dart';
import 'package:minestrix/global/smatrix.dart';

class SMatrixRoom {
  // would have liked to extends Room type, but couldn't manage to get Down Casting to work properly...
  // initialize the class, return false, if it could not generate the classes
  // i.e, it is not a valid class
  User user;
  Room room;
  SRoomType roomType = SRoomType.UserRoom; // by default
  Timeline timeline;
  bool _validSRoom = false;
  bool get validSRoom => _validSRoom;

  String get name {
    if (roomType == SRoomType.UserRoom)
      return user.displayName;
    else {
      return room.name
          .replaceFirst(SClient.SMatrixRoomPrefix + "#", "")
          .replaceFirst("smatrix_", "");
    }
  }

  Future<bool> init(Room r, SClient sclient) async {
    try {
      roomType = getSRoomType(r);
      if (roomType != null) {
        room = r;

        if (roomType == SRoomType.UserRoom) {
          String userId = SClient.getUserIdFromRoomName(room.name);
          // find local on local users
          List<User> users = room.getParticipants();
          user = findUser(users, userId);

          // or in the server ones
          if (user == null) {
            users = await room.requestParticipants();
            user = findUser(users, userId);
          }

          if (user != null) {
            /* if (room.powerLevels != null)
            print(room.powerLevels[user.id]); // throw an error....
          else
            print("error reading power levels");
          print(room.ownPowerLevel);*/
            _validSRoom = true;
            return true;
          }

          if (r.membership == Membership.invite) {
            // in the case we can't request participants
            if (user == null) {
              Profile p = await sclient.getProfileFromUserId(userId);
              user = User(userId,
                  membership: "m.join",
                  avatarUrl: p.avatarUrl.toString(),
                  displayName: p.displayname,
                  room: r);
            }
            return true; // we cannot yet access to the room participants
          }

          print("issue");
          print(r.name);
        } else if (roomType == SRoomType.Group) {
          return true;
        }
      }
    } catch (e) {
      print("crash");
    }
    return false;
  }

  static User findUser(List<User> users, String userId) {
    try {
      return users.firstWhere((User u) => userId == u.id);
    } catch (_) {
      // return null if no element

    }
    return null;
  }

  static SRoomType getSRoomType(Room room) {
    // check if is a use room, in which case, it's user must be admin
    if (room.name.startsWith("@") ||
        room.name.startsWith(SClient.SMatrixUserRoomPrefix)) {
      return SRoomType.UserRoom;
    }
    if (room.name.startsWith("#") ||
        room.name.startsWith(SClient.SMatrixRoomPrefix + "#")) {
      // now, it is a group
      return SRoomType.Group;
    }

    return null; // we don't support other room types yet
  }
}

enum SRoomType { UserRoom, Group }

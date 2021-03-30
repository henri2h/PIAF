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
      return room.name.replaceFirst("#", "").replaceFirst("smatrix_", "");
    }
  }

  Future<bool> init(Room r, SClient sclient) async {
    try {
      roomType = await getSRoomType(r);
      if (roomType != null) {
        room = r;

        if (roomType == SRoomType.UserRoom) {
          String userId = SClient.getUserIdFromRoomName(room.name);
          // find local on local users
          List<User> users = room.getParticipants();
          user = findUser(users, userId);

          // or in the server ones

          try {
            if (user == null) {
              users = await room.requestParticipants();
              user = findUser(users, userId);
            }
          } catch (e) {
            print("Could not request participants");
            print(e);
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

          print("issue, not a smatrix room : " + r.name);
        } else if (roomType == SRoomType.Group) {
          return true;
        }
      }
    } catch (e) {
      print("crash");
      print(e.toString());
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

  static Future<SRoomType> getSRoomType(Room room) async {
    // check if is a use room, in which case, it's user must be admin
    if (room.name.startsWith("@") ||
        room.name.startsWith(SClient.SMatrixUserRoomPrefix) ||
        room.name.startsWith("#")) {
      await room
          .postLoad(); // we need to find a better solution, to speed up the loading process...
      Event state = room.getState("org.matrix.msc1840");
      if (state != null) {
        // fall back
        if (room.name.startsWith("@") ||
            room.name.startsWith(SClient.SMatrixRoomPrefix + "@")) {
          // now, it is a user
          return SRoomType.UserRoom;
        } else if (room.name.startsWith("#") ||
            room.name.startsWith(SClient.SMatrixRoomPrefix + "#")) {
          // now, it is a group
          return SRoomType.Group;
        }
      }
    }

    return null; // we don't support other room types yet
  }
}

enum SRoomType { UserRoom, Group }

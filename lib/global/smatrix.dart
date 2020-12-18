/*
  Here is the main code of the smatrix client
 */

import 'dart:async';

import 'package:famedlysdk/famedlysdk.dart';

class SMatrix {
  static String SMatrixRoomPrefix = "smatrix_";
  static String SMatrixUserRoomPrefix = SMatrixRoomPrefix + "@";
  Client client;
  StreamSubscription onRoomUpdate;
  StreamSubscription onSyncUpdate;
  StreamSubscription onEventUpdate;
  StreamController<String> onTimelineUpdate = StreamController.broadcast();

  List<SMatrixRoom> srooms = [];
  List<Event> stimeline = [];

  SMatrix(Client cl) {
    client = cl;
    print("SMATRIX initialisation");
  }

  Future<void> init() async {
    // initialisation
    await loadSRooms();
    await loadNewTimeline();

    onEventUpdate ??= client.onEvent.stream.listen((EventUpdate eUp) async {
   /*   print("Event update");
      print(eUp.eventType);
      print(eUp.roomID);
      print(eUp.content);
      print(" ");*/

      if (eUp.eventType == "m.room.message") {
        await loadNewTimeline();
      }
    });
  }

  Future<void> loadNewTimeline() async {
    await loadSTimeline();
    sortTimeline();
    onTimelineUpdate.add("Update");
  }

  Future<void> loadSRooms() async {
    srooms.clear(); // clear rooms
    for (var i = 0; i < client.rooms.length; i++) {
      SMatrixRoom rs = SMatrixRoom();
      if (await rs.init(client
          .rooms[i])) // if class is correctly initialisated, we can add it
        srooms.add(rs);
    }
  }

  Future<void> loadSTimeline() async {
    stimeline.clear();
    for (SMatrixRoom sroom in srooms) {
      Timeline t = await sroom.room.getTimeline();

      for (Event e in t.events) {
        // we take only room messages
        if (e.type == EventTypes.Message || e.type == EventTypes.Encrypted) {
          stimeline.add(e);
        } else {
         // print(e.type);
        }
      }
    }
  }

  void sortTimeline() {
    stimeline.sort((a, b) {
      return b.originServerTs.compareTo(a.originServerTs);
    });
  }

  void dispose() {
    onRoomUpdate?.cancel();
    onSyncUpdate?.cancel();
    onEventUpdate?.cancel();
    onTimelineUpdate?.close();
  }

  static String getUserIdFromRoomName(String name) {
    return name.replaceFirst(SMatrixRoomPrefix, "");
  }
}

class SMatrixRoom {
  // would have liked to extends Room type, but couldn't manage to get Down Casting to work properly...
  // initialize the class, return false, if it could not generate the classes
  // i.e, it is not a valid class
  User user;
  Room room;
  bool _validSRoom = false;
  Future<bool> init(Room r) async {
    try {
      if (isValidSRoom(r)) {
        room = r;
        String userId = SMatrix.getUserIdFromRoomName(room.name);

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
      }
    } catch (e) {}
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

  static SMatrixRoom tryCast(dynamic x, {SMatrixRoom fallback}) {
    try {
      print("start");
      return (x as SMatrixRoom);
    } on TypeError catch (e) {
      print('CastError when trying to cast $x to $SMatrixRoom!');
      print(e);
      return null;
    }
  }

  static bool isValidSRoom(Room room) {
    if (room.name.startsWith(SMatrix.SMatrixRoomPrefix)) {
      // check if is a use room, in which case, it's user must be admin
      if (room.name.startsWith(SMatrix.SMatrixUserRoomPrefix)) {
        String userid = SMatrix.getUserIdFromRoomName(room.name);
        print(userid);
        return true;
      }

      return false; // we don't support other room types yet
    }
    return false;
  }
}

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

  List<Room> srooms = [];
  List<Event> stimeline = [];

  SMatrix(Client cl) {
    client = cl;
    print("SMATRIX initialisation");

    // initialisation
    loadSRooms();

    loadSTimeline();

    onRoomUpdate ??= client.onRoomUpdate.stream.listen((RoomUpdate rUp) {
      print(rUp.id);
      print(rUp.notification_count);
      //loadRooms();
    });
  }

  void loadSRooms() {
    srooms.clear(); // clear rooms
    for (var i = 0; i < client.rooms.length; i++) {
      if (isValidSRoom(client.rooms[i])) {
        srooms.add(client.rooms[i]);
      }
    }
  }

  void loadSTimeline() async {
    stimeline.clear();
    for (Room room in srooms) {
      Timeline t = await room.getTimeline();
      for (Event e in t.events) {
        stimeline.add(e);
      }
    }
  }

  void dispose() {
    onRoomUpdate?.cancel();
  }

  static String getUserIdFromRoomName(String name) {
    return name.replaceFirst(SMatrixRoomPrefix, "");
  }

  static bool isValidSRoom(Room room) {
    if (room.name.startsWith(SMatrix.SMatrixRoomPrefix)) {
      // check if is a use room, in which case, it's user must be admin
      if (room.name.startsWith(SMatrixUserRoomPrefix)) {
        String userid = getUserIdFromRoomName(room.name);
        print(userid);
        return true;
      }

      return true;
    }
    return false;
  }
}

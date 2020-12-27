/*
  Here is the main code of the smatrix client
 */

import 'dart:async';

import 'package:famedlysdk/famedlysdk.dart';

class SClient extends Client {
  static String SMatrixRoomPrefix = "smatrix_";
  static String SMatrixUserRoomPrefix = SMatrixRoomPrefix + "@";
  StreamSubscription onSyncUpdate;
  StreamSubscription onEventUpdate;
  StreamController<String> onTimelineUpdate = StreamController.broadcast();

  Map<String, SMatrixRoom> srooms = Map<String, SMatrixRoom>();
  Map<String, String> userIdToRoomId = Map<String, String>();
  List<Event> stimeline = [];

  SClient(String clientName,
      {bool enableE2eeRecovery,
      Set verificationMethods,
      Future<Database> Function(Client client) databaseBuilder})
      : super(clientName,
            verificationMethods: verificationMethods,
            databaseBuilder: databaseBuilder);

  Future<List<User>> getSfriends() async {
    if (userRoom != null && userRoom.room != null) {
      if (userRoom.room.participantListComplete) {
        return userRoom.room.getParticipants();
      } else {
        return await userRoom.room.requestParticipants();
      }
    }
    return [];
  }

  SMatrixRoom userRoom;
  bool get userRoomCreated => userRoom != null;

  Future<void> initSMatrix() async {
    // initialisation
    await loadSRooms();
    await loadNewTimeline();
    onEventUpdate ??= this.onEvent.stream.listen((EventUpdate eUp) async {
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

  bool ntimelineLock = false;
  Future<void> loadNewTimeline() async {
    if (ntimelineLock != true) {
      ntimelineLock = false;

      await loadSTimeline();
      sortTimeline();

      onTimelineUpdate.add("up");
      //await onTimelineUpdate.done;
      ntimelineLock = false;
    } else {
      print("Locked...");
    }
  }

  // load rooms
  bool sRoomLock = false;
  Future<void> loadSRooms() async {
    if (sRoomLock) {
      print("sroom lock...");
      return;
    }
    sRoomLock = true;
    srooms.clear(); // clear rooms
    userIdToRoomId.clear();

    for (var i = 0; i < rooms.length; i++) {
      SMatrixRoom rs = SMatrixRoom();
      if (await rs.init(rooms[i])) {
        // if class is correctly initialisated, we can add it
        // if we are here, it means that we have a valid smatrix room

        rs.timeline = await rs.room.getTimeline();

        srooms[rs.room.id] = rs;
        userIdToRoomId[rs.user.id] = rs.room.id;

        if (userID == rs.user.id) {
          userRoom = rs; // we have found our user smatrix room
          // this means that the client has been initialisated
          // we can load the friendsVue
        }
      }
      sRoomLock = false;
    }

    // check if user room has been created
    if (userRoom == null) {
      String roomID = await createRoom(
          name: SMatrixRoomPrefix + userID,
          topic: "Mines'Trix room name",
          visibility: Visibility.private);
      SMatrixRoom sroom = SMatrixRoom();

      sroom.init(getRoomById(roomID));
      userRoom = sroom;
    }
  }

  bool sTimelineLock = false;
  Future<void> loadSTimeline() async {
    if (sTimelineLock) {
      print("stimelinelock ...");
      return;
    }
    sTimelineLock = true;
    // init
    stimeline.clear();

    for (SMatrixRoom sroom in srooms.values) {
      Timeline t = sroom.timeline;
      final filteredEvents = t.events
          .where((e) =>
              !{
                RelationshipTypes.Edit,
                RelationshipTypes.Reaction,
                RelationshipTypes.Reply
              }.contains(e.relationshipType) &&
              {EventTypes.Message, EventTypes.Encrypted}.contains(e.type))
          .toList();

      for (var i = 0; i < filteredEvents.length; i++) {
        filteredEvents[i] = filteredEvents[i].getDisplayEvent(t);
      }

      stimeline.addAll(filteredEvents);
    }
    sTimelineLock = false;
  }

  void sortTimeline() {
    stimeline.sort((a, b) {
      return b.originServerTs.compareTo(a.originServerTs);
    });
  }

  @override
  Future<void> dispose({bool closeDatabase = true}) async {
    onSyncUpdate?.cancel();
    onEventUpdate?.cancel();
    onTimelineUpdate?.close();
    await super.dispose(closeDatabase: closeDatabase);
  }

  static String getUserIdFromRoomName(String name) {
    return name.replaceFirst(SMatrixRoomPrefix, "");
  }

  Future<Profile> getUserFromRoom(Room room) async {
    String userId = getUserIdFromRoomName(room.name);
    return await getProfileFromUserId(userId);
  }

  Future<bool> addFriend(String userId) async {
    if (userRoom != null && userRoom.room != null) {
      await userRoom.room.invite(userId);
      return true;
    }
    return false; // we haven't been able to add this user to our friend list
  }

  Future<String> getRoomDisplayName(Room room) async {
    if (room.name.startsWith(SMatrixUserRoomPrefix)) {
      Profile p = await getUserFromRoom(room);
      return p.displayname;
    }
    return "ERROR !";
  }
}

class SMatrixRoom {
  // would have liked to extends Room type, but couldn't manage to get Down Casting to work properly...
  // initialize the class, return false, if it could not generate the classes
  // i.e, it is not a valid class
  User user;
  Room room;
  Timeline timeline;
  bool _validSRoom = false;
  bool get validSRoom => _validSRoom;
  Future<bool> init(Room r) async {
    try {
      if (isValidSRoom(r)) {
        room = r;
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

  static bool isValidSRoom(Room room) {
    if (room.name.startsWith(SClient.SMatrixRoomPrefix)) {
      // check if is a use room, in which case, it's user must be admin
      if (room.name.startsWith(SClient.SMatrixUserRoomPrefix)) {
        String userid = SClient.getUserIdFromRoomName(room.name);
        print(userid);
        return true;
      }

      return false; // we don't support other room types yet
    }
    return false;
  }
}

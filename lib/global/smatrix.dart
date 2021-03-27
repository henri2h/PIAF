/*
  Here is the main code of the smatrix client
 */

import 'dart:async';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:minestrix/global/smatrix/Notifications.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';

class SClient extends Client {
  static const String SMatrixRoomPrefix = "smatrix_";
  static const String SMatrixUserRoomPrefix = SMatrixRoomPrefix + "@";
  StreamSubscription onEventUpdate;
  StreamSubscription onRoomUpdateSub; // event subscription
  StreamController<String> onTimelineUpdate = StreamController.broadcast();
  StreamController<String> onSRoomsUpdate = StreamController.broadcast();

  Map<String, SMatrixRoom> srooms = Map<String, SMatrixRoom>();

  // room sub types
  Map<String, SMatrixRoom> get sgroups => Map.from(srooms)
    ..removeWhere((key, value) => value.roomType != SRoomType.Group);
  Map<String, SMatrixRoom> get sfriends => Map.from(srooms)
    ..removeWhere((key, value) => value.roomType != SRoomType.UserRoom);

  Map<String, SMatrixRoom> sInvites =
      Map<String, SMatrixRoom>(); // friends requests

  Map<String, String> userIdToRoomId = Map<String, String>();
  List<Event> stimeline = [];

  bool _firstSync = true;

  Notifications notifications = Notifications();

  SClient(String clientName,
      {bool enableE2eeRecovery,
      Set verificationMethods,
      Future<Database> Function(Client client) databaseBuilder})
      : super(clientName,
            verificationMethods: verificationMethods,
            databaseBuilder: databaseBuilder);

  Future<List<User>> getSfriends() async {
    return (await getSUsers())
        .where((User u) => u.membership == Membership.join)
        .toList();
  }

  Future<List<User>> getSUsers() async {
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

  Timer timerCallbackRoomUpdate;
  Timer timerCallbackEventUpdate;
  Future<void> initSMatrix() async {
    // initialisation

    await loadSRooms();
    await sendInvitesToFriends();
    await loadNewTimeline();
    notifications.loadNotifications(this);

    onEventUpdate ??= this.onEvent.stream.listen((EventUpdate eUp) async {
      print("eup");
      timerCallbackEventUpdate?.cancel();
      timerCallbackEventUpdate =
          new Timer(const Duration(milliseconds: 500), () async {
        if (eUp.eventType == "m.room.message") {
          await loadNewTimeline();
        }
      });
    });

    onRoomUpdateSub ??= this.onRoomUpdate.stream.listen((RoomUpdate rUp) async {
      print("Room update");
      timerCallbackRoomUpdate?.cancel();
      timerCallbackRoomUpdate =
          new Timer(const Duration(milliseconds: 500), () async {
        print("Callback room update");
        await loadSRooms();
        await loadNewTimeline();
      });
    });
  }

  Future<void> loadNewTimeline() async {
    await loadSTimeline();
    sortTimeline();

    notifications.loadNotifications(this);

    if (_firstSync) {
      try {
        for (SMatrixRoom sr in srooms.values) {
          await sr.timeline.requestHistory();
        }
      } catch (e) {
        print("Could not get history");
        print(e);
      }
      _firstSync = false;
    }
    onTimelineUpdate.add("up");
  }

  Future<bool> setRoomState(Room room) async {
    try {
      Map<String, dynamic> content = new Map<String, dynamic>();
      content["type"] = "fr.henri2h.minestrix";
      await this.sendState(room.id, "org.matrix.msc1840", content);
      return true;
    } catch (e) {
      return false;
    }
  }

// setup the user room
  Future<bool> setupSRoom(SMatrixRoom sroom) async {
    try {
      if (sroom.room.name.startsWith(SMatrixUserRoomPrefix)) {
        print("setup room");
        String roomName = sroom.room.name.replaceFirst("smatrix_", "");
        await sroom.room.setName(roomName + " timeline");
      }
      await setRoomState(sroom.room);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool sroomsLoaded = false;
  Future<void> loadSRooms() async {
    // userRoom = null; sometimes an update miss the user room... in order to prevent indesired refresh we suppose that the room won't be removed.
    // if the user room is removed, the user should restart the app

    srooms.clear(); // clear rooms

    sInvites.clear(); // clear invites
    userIdToRoomId.clear();

    for (var i = 0; i < rooms.length; i++) {
      Room r = rooms[i];
      if (r.membership == Membership.invite) {
        print("Friendship requests sent : " + r.name);
      }
      SMatrixRoom rs = SMatrixRoom();
      if (await rs.init(r, this)) {
        print(rs.room.name);
        // if class is correctly initialisated, we can add it
        // if we are here, it means that we have a valid smatrix room
        if (r.membership == Membership.join) {
          rs.timeline = await rs.room.getTimeline();
          srooms[rs.room.id] = rs;

          // by default
          if (rs.room.pushRuleState == PushRuleState.notify)
            await rs.room.setPushRuleState(PushRuleState.mentions_only);
          if (!rs.room.tags.containsKey("m.lowpriority")) {
            await rs.room.addTag("m.lowpriority");
          }

          if (rs.roomType == SRoomType.UserRoom) {
            userIdToRoomId[rs.user.id] = rs.room.id;

            if (userID == rs.user.id) {
              userRoom = rs; // we have found our user smatrix room
              // this means that the client has been initialisated
              // we can load the friendsVue
              await setupSRoom(userRoom);
            }
          }
        }
        if (r.membership == Membership.invite) {
          print("Invite : " + r.name);

          sInvites[rs.room.id] = rs;
        }
      }
    }

    onSRoomsUpdate.add("update");
    sroomsLoaded = true;

    if (userRoom == null) print("❌ User room not found");
  }

  Future createSMatrixRoom(String name, String desc) async {
    String roomID = await createRoom(
        name: name, topic: desc, visibility: Visibility.private);
    SMatrixRoom sroom = SMatrixRoom();

    Room r = getRoomById(roomID);
    bool result = await sroom.init(r, this);

    await setupSRoom(sroom); // add the room type

    if (result)
      userRoom = sroom;
    else
      print("could not creat room ....");
  }

  Future createSMatrixUserProfile() async {
    print("Create smatrix room");
    String name = "@" + userID + " timeline";
    await createSMatrixRoom(name, "Mines'Trix room name");
  }

  Iterable<Event> getSRoomFilteredEvents(Timeline t) {
    List<Event> filteredEvents = t.events
        .where((e) =>
            !{
              RelationshipTypes.Edit,
              RelationshipTypes.Reaction,
              RelationshipTypes.Reply
            }.contains(e.relationshipType) &&
            {EventTypes.Message, EventTypes.Encrypted}.contains(e.type) &&
            !e.redacted)
        .toList();
    for (var i = 0; i < filteredEvents.length; i++) {
      filteredEvents[i] = filteredEvents[i].getDisplayEvent(t);
    }
    return filteredEvents;
  }

  Future<void> loadSTimeline() async {
    // init
    stimeline.clear();

    for (SMatrixRoom sroom in srooms.values) {
      Timeline t = sroom.timeline;
      final filteredEvents = getSRoomFilteredEvents(t);
      stimeline.addAll(filteredEvents);
    }
  }

  void sortTimeline() {
    stimeline.sort((a, b) {
      return b.originServerTs.compareTo(a.originServerTs);
    });

    print("stimeline length : " + stimeline.length.toString());
  }

  /* this function iterate over all accepted friends invitations and ensure that they are in the user room
  then it accepts all friends invitations from members of the user room
    */
  Future<void> sendInvitesToFriends() async {
    List<User> friends = await getSfriends();
    List<SMatrixRoom> sr = sInvites.values.toList();
    for (SMatrixRoom r in sr) {
      // check if the user is already in the list and accept invitation
      bool exists = (friends.firstWhere((element) => r.user.id == element.id,
              orElse: () => null) !=
          null);
      if (exists) {
        await r.room.join();
        sInvites.remove(r.room.id);
      }
    }

    List<User> users = await getSUsers();
    // iterate through rooms and add every user from thoose rooms not in our friend list
    for (SMatrixRoom r in sfriends.values) {
      bool exists = (users.firstWhere((User u) => r.user.id == u.id,
              orElse: () => null) !=
          null);
      if (!exists) {
        await userRoom.room.invite(r.user.id);
      }
    }
  }

  @override
  Future<void> dispose({bool closeDatabase = true}) async {
    onEventUpdate?.cancel();
    onTimelineUpdate?.close();
    onRoomUpdateSub?.cancel();
    await super.dispose(closeDatabase: closeDatabase);
  }

  static String getUserIdFromRoomName(String name) {
    name = name.split(" ")[0];
    return name.replaceFirst("smatrix_", "");
  }

  Future<Profile> getUserFromRoom(Room room) async {
    String userId = getUserIdFromRoomName(room.name);
    Profile p = await getProfileFromUserId(userId);
    p.userId = userId;
    return p;
  }

  Future<bool> addFriend(String userId) async {
    if (userRoom != null && userRoom.room != null) {
      await userRoom.room.invite(userId);
      return true;
    }
    return false; // we haven't been able to add this user to our friend list
  }

  Future<String> getRoomDisplayName(Room room) async {
    if (room.name.startsWith("@")) {
      Profile p = await getUserFromRoom(room);
      return p.displayname;
    }
    return "ERROR !";
  }
}

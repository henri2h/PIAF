/*
  Here is the main code of the smatrix client
 */

import 'dart:async';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';

class SClient extends Client {
  static const String SMatrixRoomPrefix = "smatrix_";
  static const String SMatrixUserRoomPrefix = SMatrixRoomPrefix + "@";
  StreamSubscription onEventUpdate;
  StreamSubscription onRoomUpdateSub; // event subscription
  StreamController<String> onTimelineUpdate = StreamController.broadcast();

  Map<String, SMatrixRoom> srooms = Map<String, SMatrixRoom>(); // friends
  Map<String, SMatrixRoom> sgroups = Map<String, SMatrixRoom>();
  Map<String, SMatrixRoom> sInvites =
      Map<String, SMatrixRoom>(); // friends requests

  Map<String, String> userIdToRoomId = Map<String, String>();
  List<Event> stimeline = [];

  bool _firstSync = true;
  // ignore: unused_field
  Timer _timer; // timer used to sync all the conversations on the first run

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

  Future<void> initSMatrix() async {
    // initialisation

    await loadSRooms();
    await sendInvitesToFriends();
    await loadNewTimeline();

    onEventUpdate ??= this.onEvent.stream.listen((EventUpdate eUp) async {
      print(eUp.type);
      if (eUp.eventType == "m.room.message") {
        await loadNewTimeline();
      }
    });

    onRoomUpdateSub ??= this.onRoomUpdate.stream.listen((RoomUpdate rUp) async {
      await loadSRooms();
      await loadNewTimeline();
    });
  }

  Future<void> loadNewTimeline() async {
    await loadSTimeline();
    sortTimeline();

    onTimelineUpdate.add("up");
    //await onTimelineUpdate.done;

    if (_firstSync) {
      Duration duration = Duration(seconds: 2); // let the app start
      _timer = Timer(duration, () async {
        print("Timer, sync threads");
        for (SMatrixRoom sr in srooms.values) {
          await sr.timeline.requestHistory();
        }
      });
      _firstSync = false;
    }
  }

  Future<void> loadSRooms() async {
    // userRoom = null; sometimes an update miss the user room... in order to prevent indesired refresh we suppose that the room won't be removed.
    // if the user room is removed, the user should restart the app

    srooms.clear(); // clear rooms
    sInvites.clear(); // clear invites
    userIdToRoomId.clear();

    for (var i = 0; i < rooms.length; i++) {
      Room r = rooms[i];
      if (r.membership == Membership.invite) {
        print("Pre Invite : " + r.name);
      }
      SMatrixRoom rs = SMatrixRoom();
      if (await rs.init(r, this)) {
        // if class is correctly initialisated, we can add it
        // if we are here, it means that we have a valid smatrix room
        if (r.membership == Membership.join) {
          rs.timeline = await rs.room.getTimeline();

          srooms[rs.room.id] = rs;
          userIdToRoomId[rs.user.id] = rs.room.id;

          if (userID == rs.user.id) {
            userRoom = rs; // we have found our user smatrix room
            // this means that the client has been initialisated
            // we can load the friendsVue
          }
        }
        if (r.membership == Membership.invite) {
          print("Invite : " + r.name);
          sInvites[rs.room.id] = rs;
        }
      }
    }

    if (userRoom == null) print("❌ User room not found");
  }

  Future createSMatrixRoom() async {
    print("Create smatrix room");
    String roomID = await createRoom(
        name: SMatrixRoomPrefix + userID,
        topic: "Mines'Trix room name",
        visibility: Visibility.private);

    SMatrixRoom sroom = SMatrixRoom();
    Room r = getRoomById(roomID);
    bool result = await sroom.init(r, this);

    /*
    Map<String, dynamic> content = Map<String, dynamic>();
    content["type"] = "fr.henri2h.smatirx";
    String res = await r.sendEvent(content,
        type: "org.matrix.msc1840"); // define room type, MSC 1840
    print(res); 
    // save user room*/ // NOT working...
    if (result)
      userRoom = sroom;
    else
      print("could not creat room ....");
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
    for (SMatrixRoom r in srooms.values) {
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
    return name.replaceFirst(SMatrixRoomPrefix, "");
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
    if (room.name.startsWith(SMatrixUserRoomPrefix)) {
      Profile p = await getUserFromRoom(room);
      return p.displayname;
    }
    return "ERROR !";
  }
}

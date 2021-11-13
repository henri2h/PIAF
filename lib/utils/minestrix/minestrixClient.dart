/*
  Here is the main code of the smatrix client
 */

import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:logging/logging.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix/utils/minestrix/minestrixTypes.dart';
import 'package:minestrix/utils/minestrix/minestrixNotifications.dart';

class MinestrixClient extends Client {
  final log = Logger("SClient");

  StreamSubscription? onRoomUpdateSub; // event subscription

  StreamController<String> onTimelineUpdate = StreamController.broadcast();

  StreamController<String> onSRoomsUpdate = StreamController.broadcast();

  Map<String, MinestrixRoom> srooms = Map<String, MinestrixRoom>();

  // room sub types
  Map<String, MinestrixRoom> get sgroups => Map.from(srooms)
    ..removeWhere((key, value) => value.roomType != SRoomType.Group);

  Map<String, MinestrixRoom> get sfriends => Map.from(srooms)
    ..removeWhere((key, value) => value.roomType != SRoomType.UserRoom);

  Map<String, MinestrixRoom> get following => Map.from(srooms)
    ..removeWhere((key, value) => value.roomType != SRoomType.UserRoom);

  Map<String, MinestrixRoom> sInvites =
      Map<String, MinestrixRoom>(); // friends requests

  Map<String, String> userIdToRoomId = Map<String, String>();
  List<Event> stimeline = [];

  bool _firstSync = true;

  MinestrixNotifications notifications = MinestrixNotifications();

  MinestrixClient(String clientName, {bool? enableE2eeRecovery, Set<KeyVerificationMethod>? verificationMethods})
      : super(
          clientName,
          verificationMethods: verificationMethods,
          databaseBuilder: (Client client) async {
            final db = FamedlySdkHiveDatabase(client.clientName);
            await db.open();
            print("[ db ] :  loaded");
            return db;
          },
        );

  Future<List<User>> getFollowers() async {
    return (await getSUsers())
        .where((User u) => u.membership == Membership.join)
        .toList();
  }

  Future<List<User>> getSUsers() async {
    if (userRoom != null && userRoom!.room != null) {
      if (userRoom!.room!.participantListComplete) {
        return userRoom!.room!.getParticipants();
      } else {
        return await userRoom!.room!.requestParticipants();
      }
    }
    return [];
  }

  MinestrixRoom? userRoom;
  bool get userRoomCreated => userRoom != null;

  Timer? timerCallbackRoomUpdate;
  Timer? timerCallbackEventUpdate;
  Future<void> initSMatrix() async {
    // initialisation

    await loadSRooms();
    await autoFollowFollowers(); // TODO : Let's see if we keep this in the future
    await loadNewTimeline();
    notifications.loadNotifications(this);

    // for MinestrixRooms
    onRoomUpdateSub ??= this.onEvent.stream.listen((EventUpdate rUp) async {
      if (srooms.containsKey(rUp.roomID)) {
        // we use a timer to prevent calling
        timerCallbackRoomUpdate?.cancel();
        timerCallbackRoomUpdate =
            new Timer(const Duration(milliseconds: 500), () async {
          log.info("MinesTrix : callback new message");
          await loadNewTimeline(); // new message, we only need to rebuild timeline
        });
      }
    });
  }

  Future<void> loadNewTimeline() async {
    await loadSTimeline();
    sortTimeline();

    notifications.loadNotifications(this);

    // On first sync we fetch all the event history
    if (_firstSync) {
      try {
        int n = srooms.values.length;
        int counter = 0;
        for (MinestrixRoom sr in srooms.values) {
          await sr.timeline!.requestHistory();

          log.info("First sync progress : " + (counter / n * 100).toString());
          counter++;
        }
      } catch (e) {
        log.severe("Initial sync : failed to get history", e);
      }
      _firstSync = false;
    }
    onTimelineUpdate.add("up");
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
        log.info("Friendship requests sent : " + r.name);
      }

      MinestrixRoom? rs = await MinestrixRoom.loadMinesTrixRoom(r, this);
      if (rs != null) {
        // if class is correctly initialisated, we can add it
        // if we are here, it means that we have a valid smatrix room

        if (r.membership == Membership.join) {
          rs.timeline = await rs.room!.getTimeline();
          srooms[rs.room!.id] = rs;

          // by default
          if (rs.room!.pushRuleState == PushRuleState.notify)
            await rs.room!.setPushRuleState(PushRuleState.mentionsOnly);
          if (!rs.room!.tags.containsKey("m.lowpriority")) {
            await rs.room!.addTag("m.lowpriority");
          }

          // check if this room is a user thread
          if (rs.roomType == SRoomType.UserRoom) {
            userIdToRoomId[rs.user!.id] = rs.room!.id;

            if (userID == rs.user!.id) {
              userRoom = rs; // we have found our user smatrix room
              // this means that the client has been initialisated
              // we can load the friendsVue
            }
          }
        }
        if (r.membership == Membership.invite) {
          print("Invite : " + r.name);

          sInvites[rs.room!.id] = rs;
        }
      }
    }

    onSRoomsUpdate.add("update");
    print("[smatrix] : sroom update");
    sroomsLoaded = true;

    if (userRoom == null) log.severe("❌ User room not found");
  }

  Future<String> createMinestrixAccount(String name, String desc) async {
    String roomID = await createRoom(
        name: name,
        topic: desc,
        visibility: Visibility.private,
        creationContent: {"type": MinestrixTypes.account});

    // launch sync
    await loadSRooms();
    await loadNewTimeline();

    return roomID;
  }

  Future createSMatrixUserProfile() async {
    log.info("Create smatrix room");
    String name = userID! + " timeline";
    await createMinestrixAccount(name, "A Mines'Trix profile");
  }

  Iterable<Event> getSRoomFilteredEvents(Timeline t) {
    List<Event> filteredEvents = t.events
        .where((e) =>
            !{
              RelationshipTypes.edit,
              RelationshipTypes.reaction,
              RelationshipTypes.reply
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

    for (MinestrixRoom sroom in srooms.values) {
      Timeline t = sroom.timeline!;
      final filteredEvents = getSRoomFilteredEvents(t);
      stimeline.addAll(filteredEvents);
    }
  }

  void sortTimeline() {
    stimeline.sort((a, b) {
      return b.originServerTs.compareTo(a.originServerTs);
    });

    log.info("stimeline length : " + stimeline.length.toString());
  }

  /* this function iterate over all accepted friends invitations and ensure that they are in the user room
  then it accepts all friends invitations from members of the user room
    */
  Future<void> autoFollowFollowers() async {
    List<User> followers = await getFollowers();
    List<MinestrixRoom> sr = sInvites.values.toList();
    for (MinestrixRoom r in sr) {
      // check if the user is already in the list and accept invitation
      bool exists = (followers.firstWhereOrNull((element) => r.user!.id == element.id) !=
          null);
      if (exists) {
        await r.room!.join();
        sInvites.remove(r.room!.id);
      }
    }

    List<User> users = await getSUsers();
    // iterate through rooms and add every user from thoose rooms not in our friend list
    for (MinestrixRoom r in sfriends.values) {
      bool exists = (users.firstWhereOrNull((User u) => r.user!.id == u.id) !=
          null);
      if (!exists) {
        await userRoom!.room!.invite(r.user!.id);
      }
    }
  }

  @override
  Future<void> dispose({bool closeDatabase = true}) async {
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
    if (userRoom != null && userRoom!.room != null) {
      await userRoom!.room!.invite(userId);
      return true;
    }
    return false; // we haven't been able to add this user to our friend list
  }

  Future<String?> getRoomDisplayName(Room room) async {
    if (room.name.startsWith("@")) {
      Profile p = await getUserFromRoom(room);
      return p.displayName;
    }
    return "ERROR !";
  }

  Future<String> createMinestrixGroup(String name, String desc) async{
    String roomID = await createRoom(
        name: name,
        topic: desc,
        visibility: Visibility.private,
        creationContent: {"type": MinestrixTypes.group});

    // launch sync
    await loadSRooms();
    await loadNewTimeline();

    return roomID;
  }
}

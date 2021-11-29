/*
  Here is the main code of the smatrix client
 */

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:hive_flutter/adapters.dart';
import 'package:logging/logging.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/Fluffychat/FluffyboxDatabase.dart';
import 'package:minestrix/utils/minestrix/minestrixFriendsSuggestions.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';
import 'package:minestrix/utils/minestrix/minestrixTypes.dart';
import 'package:minestrix/utils/minestrix/minestrixNotifications.dart';
import 'package:minestrix/utils/platforms_info.dart';
import 'package:path_provider/path_provider.dart';

class MinestrixClient extends Client {
  final log = Logger("MinestrixClient");

  StreamSubscription? onRoomUpdateSub; // event subscription

  StreamController<String> onTimelineUpdate = StreamController.broadcast();

  StreamController<String> onSRoomsUpdate = StreamController.broadcast();

  Map<String, MinestrixRoom> srooms = Map<String, MinestrixRoom>();
  Map<String, bool> roomsLoaded = Map<String, bool>();

  // room sub types
  Map<String, MinestrixRoom> get sgroups => Map.from(srooms)
    ..removeWhere((key, value) => value.roomType != SRoomType.Group);

  Map<String, MinestrixRoom> get sfriends => Map.from(srooms)
    ..removeWhere((key, value) => value.roomType != SRoomType.UserRoom);

  Map<String, MinestrixRoom> get following => Map.from(srooms)
    ..removeWhere((key, value) => value.roomType != SRoomType.UserRoom);

  Map<String, MinestrixRoom> minestrixInvites = Map<String, MinestrixRoom>();
  /* => Map.from(srooms)
    ..removeWhere((key, MinestrixRoom room) =>
        room.room.membership != Membership.invite); // friends requests*/

  Map<String, String> userIdToRoomId = Map<String, String>();
  List<Event> stimeline = [];

  late MinestrixNotifications notifications;
  late MinestrixFriendsSugestion friendsSuggestions;

  MinestrixClient(String clientName,
      {Set<KeyVerificationMethod>? verificationMethods})
      : super(clientName, verificationMethods: verificationMethods,
            databaseBuilder: (Client client) async {
          return await FlutterFluffyBoxDatabase.databaseBuilder(client);
        }, legacyDatabaseBuilder: (Client client) async {
          if (PlatformInfos.isBetaDesktop) {
            Hive.init((await getApplicationSupportDirectory()).path);
          } else {
            await Hive.initFlutter();
          }
          final db = FamedlySdkHiveDatabase(client.clientName);
          await db.open();
          print("[ legacy db ] :  loaded");
          return db;
        }, supportedLoginTypes: {
          AuthenticationTypes.password,
          AuthenticationTypes.sso
        }, compute: compute) {
    notifications = MinestrixNotifications();
    friendsSuggestions = MinestrixFriendsSugestion(this);
  }

  Future<List<User>> getFollowers() async {
    return (await getSUsers())
        .where((User u) => u.membership == Membership.join)
        .toList();
  }

  Future<List<User>> getSUsers() async {
    if (userRoom != null) {
      if (userRoom!.room.participantListComplete) {
        return userRoom!.room.getParticipants();
      } else {
        return await userRoom!.room.requestParticipants();
      }
    }
    return [];
  }

  MinestrixRoom? userRoom;
  bool get userRoomCreated => userRoom != null;

  Timer? timerCallbackRoomUpdate;
  Timer? timerCallbackEventUpdate;

  Future<void> updateAll() async {
    await loadSRooms();
    await autoFollowFollowers(); // TODO : Let's see if we keep this in the future
    await loadNewTimeline();
    notifications.loadNotifications(this);
  }

  Future<void> initSMatrix() async {
    // initialisation
    await updateAll();

    // for MinestrixRooms
    onRoomUpdateSub ??= this.onEvent.stream.listen((EventUpdate rUp) async {
      if (srooms.containsKey(rUp.roomID)) {
        // we use a timer to prevent calling
        timerCallbackEventUpdate?.cancel();
        timerCallbackEventUpdate =
            new Timer(const Duration(milliseconds: 300), () async {
          print("[ sync ] : New event");
          await loadNewTimeline(); // new message, we only need to rebuild timeline
        });
      } else {
        if (roomsLoaded.containsKey(rUp.roomID) == false) {
          Room? r = getRoomById(rUp.roomID);
          if (r != null) {
            print("[ client ] : update rooms list");
            await checkRoom(r);

            onTimelineUpdate.add("up");
          }
        }
      }
    });
    onFirstSync.stream.listen((bool result) async {
      if (result) {
        print("[ client ] : on first sync completed");
        await updateAll();
      }
    });
  }

  Future<void> requestHistoryForSRooms() async {
    int n = srooms.values.length;
    int counter = 0;
    for (MinestrixRoom sr in srooms.values) {
      await sr.timeline!.requestHistory();

      print("First sync progress : " + (counter / n * 100).toString());
      counter++;
    }
  }

  /// load timeline and request history
  Future<void> loadNewTimeline() async {
    await requestHistoryForSRooms(); // TODO : don't request more history than necessary

    await loadSTimeline();
    sortTimeline();

    notifications.loadNotifications(this);

    onTimelineUpdate.add("up");
  }

  /// check if the specified room is a smatrix room or not.
  /// If yes, then store it in srooms list
  Future<void> checkRoom(Room r) async {
    MinestrixRoom? rs = await MinestrixRoom.loadMinesTrixRoom(r, this);

    // write that we have loaded this room in order to not process it twice
    roomsLoaded[r.id] = false;

    if (rs != null) {
      // if class is correctly initialisated, we can add it
      // if we are here, it means that we have a valid smatrix room

      if (r.membership == Membership.join) {
        try {
          rs.timeline = await rs.room.getTimeline();
          srooms[rs.room.id] = rs;

          // by default
          if (rs.room.pushRuleState == PushRuleState.notify)
            await rs.room.setPushRuleState(PushRuleState.mentionsOnly);
          if (!rs.room.tags.containsKey("m.lowpriority")) {
            await rs.room.addTag("m.lowpriority");
          }

          // check if this room is a user thread
          if (rs.roomType == SRoomType.UserRoom) {
            userIdToRoomId[rs.user.id] = rs.room.id;

            if (userID == rs.user.id) {
              userRoom = rs; // we have found our user smatrix room
              // this means that the client has been initialisated
              // we can load the friendsVue

              print("Found MinesTRIX account : " + rs.name);
              onTimelineUpdate.add("up");
            }
          }
        } catch (e) {
          print(e.toString());
          print("Could not load room : " + r.displayname);
        }
      } else if (r.membership == Membership.invite) {
        minestrixInvites[rs.room.id] = rs;
      }
    }
  }

  bool sroomsLoaded = false;
  Future<void> loadSRooms() async {
    // userRoom = null; sometimes an update miss the user room... in order to prevent indesired refresh we suppose that the room won't be removed.
    // if the user room is removed, the user should restart the app
    await roomsLoading;
    print("[ client ] : Loading MinesTRIX rooms");

    srooms.clear(); // clear rooms
    roomsLoaded.clear();

    minestrixInvites.clear(); // clear invites
    userIdToRoomId.clear();

    for (var i = 0; i < rooms.length; i++) {
      Room r = rooms[i];
      await checkRoom(r);
    }

    onSRoomsUpdate.add("update");
    print("Minestrix room update");
    sroomsLoaded = true;

    if (userRoom == null) print("❌ User room not found");
  }

  Future<String> createMinestrixAccount(String name, String desc) async {
    String roomID = await createRoom(
        name: name,
        topic: desc,
        visibility: Visibility.private,
        creationContent: {"type": MinestrixTypes.account});

    return roomID;
  }

  Future createSMatrixUserProfile() async {
    String name = userID! + " timeline";
    await createMinestrixAccount(name, "A Mines'Trix profile");

    // refresh everything
    await updateAll();
  }

  Iterable<Event> getSRoomFilteredEvents(Timeline t,
      {List<String> eventTypesFilter: const [
        EventTypes.Message,
        EventTypes.Encrypted
      ]}) {
    List<Event> filteredEvents = t.events
        .where((e) =>
            !{
              RelationshipTypes.edit,
              RelationshipTypes.reaction,
              RelationshipTypes.reply
            }.contains(e.relationshipType) &&
            eventTypesFilter.contains(e.type) &&
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
    List<MinestrixRoom> sr = minestrixInvites.values.toList();
    for (MinestrixRoom r in sr) {
      // check if the user is already in the list and accept invitation
      bool exists =
          (followers.firstWhereOrNull((element) => r.user.id == element.id) !=
              null);
      if (exists) {
        await r.room.join();
        minestrixInvites.remove(r.room.id);
      }
    }

    List<User> users = await getSUsers();
    // iterate through rooms and add every user from thoose rooms not in our friend list
    for (MinestrixRoom r in sfriends.values) {
      bool exists =
          (users.firstWhereOrNull((User u) => r.user.id == u.id) != null);
      if (!exists) {
        await userRoom!.room.invite(r.user.id);
      }
    }
  }

  @override
  Future<void> dispose({bool closeDatabase = true}) async {
    onTimelineUpdate.close();
    onRoomUpdateSub?.cancel();
    await super.dispose(closeDatabase: closeDatabase);
  }

  Future<bool> addFriend(String userId) async {
    if (userRoom != null) {
      await userRoom!.room.invite(userId);
      return true;
    }
    return false; // we haven't been able to add this user to our friend list
  }

  Future<String> createMinestrixGroup(String name, String desc) async {
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

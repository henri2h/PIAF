import 'package:matrix/matrix.dart';
import 'package:piaf/chat/minestrix_chat.dart';
import 'package:piaf/chat/utils/matrix/power_levels_extension.dart';

// TODO: check this class, should not anymore be needed
/// A space to store information about a particular user
extension ProfileSpace on Client {
  static const String profileSpaceRoomType = "msczzzz.profile";
  static String getAliasName(String userID) => "#mscXXXX.$userID";

  /// get the current use profile room.
  ///
  /// If [userID] is not provided, we use the current logged in userID instead.
  Room? getProfileSpace({String? userID}) {
    userID ??= this.userID;
    // did we get a non null matrix ID ?
    if (userID == null) return null;

    return getRoomByAlias(getAliasName(userID));
  }

  Future<List<SpaceRoomsChunk>?> getProfileSpaceHierarchy(String userId) async {
    var roomId = await getRoomIdByAlias(ProfileSpace.getAliasName(userId));
    if (roomId.roomId == null) return null;
    return (await getSpaceHierarchy(roomId.roomId!)).rooms;
  }

  /// Create a new user profile room
  Future<void> createProfileSpace() async {
    if (getProfileSpace() == null && userID != null) {
      Profile p = await getProfileFromUserId(userID!);

      String id = await createSpace(
        name: "${p.displayName ?? userID!} space",
        visibility: Visibility.public,
      );

      if (getRoomById(id) == null) {
        // Wait for room actually appears in sync
        await onSync.stream
            .firstWhere((sync) => sync.rooms?.join?.containsKey(id) ?? false);
      }

      Room? r = getRoomById(id);
      if (r != null) {
        await r.client.setRoomStateWithKey(
            r.id, "m.room.type", "", {"type": profileSpaceRoomType});
        await r.client.setRoomStateWithKey(r.id, "m.room.history_visibility",
            "", {"history_visibility": "world_readable"});
        await r.setPowerLevels({"events_default": 100});

        await r.setCanonicalAlias(getAliasName(userID!));
      } else {
        Logs().w("Room is null");
      }
    } else {
      Logs().i("Profile room already exists not creating a new one.");
    }
  }
}

extension ProfileRoom on Room {
  bool get isProfileRoom =>
      isSpace && subtype == ProfileSpace.profileSpaceRoomType;

  /// Create new stories room and add it to the profile room directory
  Future<String> createAndAddStoriesRoomToSpace({List<String>? invite}) async {
    String id = await client.createStoryRoom(invite: invite);

    // and add it to the room directory
    await setSpaceChild(id);

    return id;
  }

  /// Remove a child of this space.
  Future<void> removeSpaceChild(String roomId) async {
    await client.setRoomStateWithKey(id, EventTypes.SpaceChild, roomId, {});
    try {
      await client.setRoomStateWithKey(roomId, EventTypes.SpaceParent, id, {});
    } catch (e) {
      Logs().e("Could not remove space parent for $id in $roomId", e);
    }
    return;
  }
}

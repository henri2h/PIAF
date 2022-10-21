import 'package:collection/src/iterable_extensions.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

extension MinestrixFriendsSugestion on Client {
  /// Add a simple way to display friend suggestions
  Future<List<Profile>> getSuggestionsSimple() async {
    SearchUserDirectoryResponse search =
        await searchUserDirectory("", limit: 50);

    search.results.removeWhere((profile) =>
        sfriends.firstWhereOrNull((Room r) => r.creatorId == profile.userId) !=
        null);
    return search.results;
  }

  /// Get friend suggestions by looking in smatrix rooms
  Future<List<Profile>> getFriendsSuggestions() async {
    Map<String, ProfileCount> profiles = <String, ProfileCount>{};

    for (Room r in rooms) {
      //await r.requestParticipants();
      for (User u in r.getParticipants()) {
        String id = u.id;

        if (profiles[id] != null) {
          profiles[id]!.a();
        } else {
          Profile p = Profile(
              avatarUrl: u.avatarUrl, displayName: u.displayName, userId: u.id);

          profiles[id] = ProfileCount(p);
        }
      }
    }
    List<ProfileCount> ps = profiles.values
        .sorted((ProfileCount a, ProfileCount b) => b.pos.compareTo(a.pos))
        .toList();

    // TODO: find which room we may use. Maybe define a main room.
    if (minestrixUserRoom.isNotEmpty) {
      ps.removeWhere((ProfileCount profile) =>
          minestrixUserRoom.first.getParticipants().firstWhereOrNull(
              (User element) => element.id == profile.p.userId) !=
          null);
    }

    // get the 20 best results
    return ps.take(20).map<Profile>((ProfileCount p) => p.p).toList();
  }
}

class ProfileCount {
  late Profile p;
  late int pos;
  ProfileCount(Profile pIn) : p = pIn {
    pos = 0;
  }
  void a() {
    pos += 1;
  }
}

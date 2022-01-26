import 'package:collection/src/iterable_extensions.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class MinestrixFriendsSugestion {
  final MinestrixClient client;
  MinestrixFriendsSugestion(this.client);

  /// Add a simple way to display friend suggestions
  Future<List<Profile>> getSuggestionsSimple() async {
    SearchUserDirectoryResponse search =
        await client.searchUserDirectory("", limit: 50);

    search.results.removeWhere((profile) =>
        client.sfriends.values
            .firstWhereOrNull((element) => element.userID == profile.userId) !=
        null);
    return search.results;
  }

  /// Get friend suggestions by looking in smatrix rooms
  Future<List<Profile>> getSuggestions() async {
    Map<String, ProfileCount> profiles = Map<String, ProfileCount>();

    for (Room r in client.rooms) {
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

    ps.removeWhere((ProfileCount profile) =>
        client.userRoom!.room.getParticipants().firstWhereOrNull(
            (User element) => element.id == profile.p.userId) !=
        null);

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

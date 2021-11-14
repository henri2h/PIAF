import 'package:collection/src/iterable_extensions.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class MinestrixFriendsSugestion {
  final MinestrixClient client;
  MinestrixFriendsSugestion(this.client);

  Future<List<Profile>> getSuggestions() async {
    SearchUserDirectoryResponse search =
        await client.searchUserDirectory("", limit: 50);

    search.results.removeWhere((profile) =>
        client.sfriends.values
            .firstWhereOrNull((element) => element.user.id == profile.userId) !=
        null);
    return search.results;
  }
}

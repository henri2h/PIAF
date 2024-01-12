import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';

class Community {
  final Room space;
  final List<Room> children;

  Community(this.space) : children = getChildren(space);

  static List<Room> getChildren(Room space) {
    List<Room> spaceChilds = [];

    for (var child in space.spaceChildren) {
      if (child.roomId != null && (child.via?.isNotEmpty ?? false)) {
        final room = space.client.getRoomById(child.roomId!);

        if (room?.isSpace == false && room?.isFeed == true) {
          spaceChilds.add(room!);
        }
      }
    }

    return spaceChilds;
  }
}

extension Communities on Client {
  List<Community> getCommunities() => rooms
      .where((Room r) => r.isSpace)
      .map((e) => Community(e))
      .where((element) => element.children.isNotEmpty)
      .toList();
}

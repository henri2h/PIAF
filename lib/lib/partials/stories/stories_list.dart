import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/partials/stories/stories_circle.dart';

class StoriesList extends StatefulWidget {
  const StoriesList(
      {super.key,
      required this.client,
      this.restrictUserID,
      this.restrictRoom,
      this.allowCreatingStory = true})
      : assert(restrictRoom == null || restrictUserID == null);

  final Client client;
  final String? restrictUserID;
  final List<Room>? restrictRoom;
  final bool allowCreatingStory;

  @override
  StoriesListState createState() => StoriesListState();
}

class StoriesListState extends State<StoriesList> {
  final bool _creatingStorie = false;

  @override
  Widget build(BuildContext context) {
    List<Room> storieRooms;
    final client = widget.client;

    if (widget.restrictUserID != null) {
      storieRooms =
          client.getStorieRoomsFromUser(userID: widget.restrictUserID!);
    } else if (widget.restrictRoom != null) {
      storieRooms = widget.restrictRoom!
          .where((room) => room.type == StoriesExtension.storiesRoomType)
          .toList();
    } else {
      storieRooms = client.storiesRoomsSorted;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (widget.allowCreatingStory)
            FutureBuilder<Profile>(
                future: client.getProfileFromUserId(client.userID!),
                builder: (context, snap) {
                  final profile = snap.data;
                  return Column(
                    children: [
                      Material(
                          shape: const CircleBorder(),
                          color: null,
                          child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Material(
                                shape: const CircleBorder(),
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: MaterialButton(
                                    padding: EdgeInsets.zero,
                                    minWidth: 0,
                                    onPressed: () => client
                                        .openStoryEditModalOrCreate(context),
                                    child: Stack(
                                      children: [
                                        MatrixImageAvatar(
                                          url: profile?.avatarUrl,
                                          defaultText: profile?.displayName ??
                                              client.userID!,
                                          width: MinestrixAvatarSizeConstants
                                              .medium,
                                          height: MinestrixAvatarSizeConstants
                                              .medium,
                                          client: client,
                                        ),
                                        if (_creatingStorie)
                                          const CircularProgressIndicator(
                                              color: Colors.white),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor:
                                                Theme.of(context).cardColor,
                                            child: CircleAvatar(
                                                radius: 10,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                child: Icon(Icons.add,
                                                    size: 10,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ))),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: SizedBox(
                          height: 24,
                          child: Text("Add a story",
                              maxLines: 1, style: TextStyle(fontSize: 10)),
                        ),
                      )
                    ],
                  );
                }),
          for (Room room in storieRooms)
            Builder(builder: (context) {
              final hasPosts = room.hasPosts;
              return Opacity(
                  opacity: hasPosts ? 1 : 0.65,
                  child: StorieCircle(room: room, hasPosts: hasPosts));
            }),
        ],
      ),
    );
  }
}

extension on Room {
  bool get hasPosts {
    if (membership == Membership.invite) return true;
    final lastEvent = this.lastEvent;
    if (lastEvent == null) return false;
    if (lastEvent.type != EventTypes.Message) return false;
    if (DateTime.now().difference(lastEvent.originServerTs).inHours >
        StoriesExtension.lifeTimeInHours) {
      return false;
    }
    return true;
  }
}

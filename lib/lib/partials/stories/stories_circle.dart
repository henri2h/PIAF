import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/pages/matrix_stories_page.dart';

class StorieCircle extends StatefulWidget {
  const StorieCircle(
      {super.key,
      required this.room,
      this.dot = false,
      required this.hasPosts});
  final Room room;
  final bool dot;
  final bool hasPosts;

  @override
  StorieCircleState createState() => StorieCircleState();
}

class StorieCircleState extends State<StorieCircle> {
  late Future<Profile> getProfile;
  late Room room;
  String? userID;

  @override
  void initState() {
    super.initState();

    room = widget.room;
    userID = room.creatorId;
    if (userID != null) {
      getProfile = widget.room.client.getProfileFromUserId(userID!);
    }
  }

  bool get unread =>
      room.membership == Membership.invite ||
      room.hasNewMessages ||
      widget.hasPosts;

  @override
  Widget build(BuildContext context) {
    if (room.lastEvent != null && userID != null) {
      return Column(
        children: [
          FutureBuilder<Profile>(
              future: getProfile,
              builder: (BuildContext context, AsyncSnapshot<Profile> p) {
                return Column(
                  children: [
                    Material(
                      shape: const CircleBorder(),
                      color: unread
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Material(
                          shape: const CircleBorder(),
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: MaterialButton(
                              padding: EdgeInsets.zero,
                              minWidth: 0,
                              onPressed: () async {
                                await room.client.roomsLoading;
                                if (room.membership == Membership.invite) {
                                  await room.join();
                                }
                                if (context.mounted) {
                                  await MatrixStoriesPage.show(context, room);
                                }
                              },
                              shape: const CircleBorder(),
                              child: MatrixImageAvatar(
                                url: p.data?.avatarUrl,
                                defaultText: p.data?.displayName ?? userID!,
                                width: MinestrixAvatarSizeConstants.medium,
                                height: MinestrixAvatarSizeConstants.medium,
                                client: room.client,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 80,
                        height: 24,
                        child: Text(p.data?.displayName ?? userID!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10)),
                      ),
                    )
                  ],
                );
              }),
        ],
      );
    }
    return const Icon(Icons.error);
  }
}

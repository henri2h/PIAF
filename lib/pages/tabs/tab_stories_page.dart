import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';
import 'package:minestrix/chat/pages/matrix_stories_page.dart';
import 'package:minestrix/chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix/chat/utils/matrix_widget.dart';

@RoutePage()
class TabStoriesPage extends StatefulWidget {
  const TabStoriesPage({super.key});

  @override
  TabStoriesPageState createState() => TabStoriesPageState();
}

class TabStoriesPageState extends State<TabStoriesPage> {
  final bool _creatingStorie = false;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    List<Room> storieRooms = client.storiesRoomsSorted;

    return Scaffold(
      appBar: AppBar(title: const Text("Stories")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.extent(
          maxCrossAxisExtent: 300,
          children: [
            FutureBuilder<Profile>(
                future: client.getProfileFromUserId(client.userID!),
                builder: (context, snap) {
                  final profile = snap.data;
                  return Card(
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () => client.openStoryEditModalOrCreate(context),
                      child: Stack(
                        children: [
                          if (_creatingStorie)
                            const CircularProgressIndicator(
                                color: Colors.white),
                          MatrixImageAvatar(
                              url: profile?.avatarUrl,
                              defaultText:
                                  profile?.displayName ?? client.userID!,
                              unconstraigned: true,
                              client: client,
                              shape: MatrixImageAvatarShape.none),
                          const Positioned(
                              right: 10,
                              top: 10,
                              child: Icon(Icons.add_circle, size: 34))
                        ],
                      ),
                    ),
                  );
                }),
            for (Room room
                in storieRooms.where((room) => room.creatorId != client.userID))
              Builder(builder: (context) {
                final hasPosts = room.hasPosts;
                late Future<Profile> getProfile;

                bool unread = room.hasNewMessages || hasPosts;
                final userID = room.creatorId;
                if (userID != null) {
                  getProfile = room.client.getProfileFromUserId(userID);
                }
                return FutureBuilder<Profile>(
                    future: getProfile,
                    builder:
                        (BuildContext context, AsyncSnapshot<Profile> profile) {
                      return Card(
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: () async {
                            await room.client.roomsLoading;
                            if (room.membership == Membership.invite) {
                              await room.join();
                            }
                            if (context.mounted) {
                              await MatrixStoriesPage.show(context, room);
                            }
                          },
                          child: Stack(
                            children: [
                              Opacity(
                                opacity: hasPosts ? 1 : 0.65,
                                child: MatrixImageAvatar(
                                    url: profile.data?.avatarUrl,
                                    defaultText: profile.data?.displayName ??
                                        client.userID!,
                                    unconstraigned: true,
                                    client: client,
                                    shape: MatrixImageAvatarShape.none),
                              ),
                              if (profile.hasData)
                                Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: Text(profile.data!.displayName ??
                                        userID ??
                                        ''))
                            ],
                          ),
                        ),
                      );
                    });
              }),
          ],
        ),
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

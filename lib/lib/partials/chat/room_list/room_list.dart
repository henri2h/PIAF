import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/chat/room_list/room_list_title.dart';
import 'package:minestrix_chat/partials/chat/room_list/room_list_items/room_list_item.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';
import 'package:minestrix_chat/pages/chat_page_items/chat_page_spaces_list.dart';

import '../spaces/list/spaces_list.dart';
import 'room_list_filter/room_list_filter.dart';
import 'room_list_items/room_list_item_presence.dart';
import 'room_list_items/room_list_item_slidable.dart';
import 'room_list_search_button.dart';

class RoomList extends StatelessWidget {
  ///  [allowPop]
  const RoomList(
      {Key? key,
      required this.onSelection,
      required this.client,
      required this.selectedRoomId,
      required this.selectedSpace,
      required this.controller,
      required this.sortedRooms,
      required this.isMobile,
      required this.allowPop,
      this.appBarColor,
      this.onAppBarClicked})
      : super(key: key);

  final Function(String?) onSelection;
  final String? selectedRoomId;
  final String? selectedSpace;
  final Client client;
  final List<Room>? sortedRooms;
  final ScrollController controller;
  final bool allowPop;
  final bool isMobile; // adapted for small screens
  final Color? appBarColor;
  final VoidCallback? onAppBarClicked;
  final displaySpaceList = true;

  @override
  Widget build(BuildContext context) {
    List<CachedPresence>? presences;

    if (selectedSpace == CustomSpacesTypes.active) {
      presences = client.presences.values.where((element) {
        if (client.getDirectChatFromUserId(element.userid) == null) {
          return false;
        }
        return element.currentlyActive == true;
      }).toList()
        ..sort((a, b) {
          if (a.lastActiveTimestamp != null && b.lastActiveTimestamp != null) {
            return b.lastActiveTimestamp!.compareTo(a.lastActiveTimestamp!);
          }
          return 0;
        });
    }

    return Column(
      children: [
        if (!isMobile && selectedSpace == CustomSpacesTypes.home)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                    title: const Text("Your chats"),
                    leading: const Icon(Icons.message),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder),
                          onPressed: () {},
                        ),
                      ],
                    )),
              ),
              RoomListFilter(client: client),
              Padding(
                padding: const EdgeInsets.all(8),
                child: RoomListSearchButton(
                  client: client,
                  onSelection: onSelection,
                  onUserTap: onAppBarClicked,
                ),
              ),
            ],
          ),
        Expanded(
          child: displaySpaceList
              ? ChatPageSpaceList(
                  mobile: isMobile,
                  scrollController: controller,
                )
              : CustomScrollView(
                  cacheExtent: 400,
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: controller,
                  slivers: [
                    if (isMobile || selectedSpace != CustomSpacesTypes.home)
                      SliverAppBar(
                          key: const Key("room_list_title"),
                          pinned: true,
                          elevation: 0,
                          automaticallyImplyLeading: isMobile,
                          backgroundColor: appBarColor ??
                              (isMobile
                                  ? Theme.of(context)
                                      .scaffoldBackgroundColor
                                      .withAlpha(200)
                                  : null),
                          expandedHeight: 60,
                          collapsedHeight: 60,
                          flexibleSpace: Builder(builder: (context) {
                            final result = SizedBox(
                              height: 60,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 4,
                                    child: StreamBuilder<SyncStatusUpdate>(
                                        stream: client.onSyncStatus.stream,
                                        builder: (context, snap) {
                                          if (snap.hasData) {
                                            if (snap.data!.status ==
                                                    SyncStatus.processing &&
                                                ![null, 0, 1.0].contains(
                                                    snap.data!.progress)) {
                                              return LinearProgressIndicator(
                                                  value: snap.data!.progress!);
                                            }
                                          }
                                          return Container();
                                        }),
                                  ),
                                  RoomListTitle(
                                      client: client,
                                      allowPop: allowPop,
                                      mobile: isMobile,
                                      selectedSpace: selectedSpace,
                                      onRoomSelected: onSelection,
                                      onTap: onAppBarClicked)
                                ],
                              ),
                            );

                            return isMobile
                                ? ClipRect(
                                    child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 10, sigmaY: 10),
                                        child: result),
                                  )
                                : result;
                          })),
                    if (isMobile && selectedSpace == CustomSpacesTypes.home)
                      SliverAppBar(
                        elevation: 0,
                        expandedHeight: 76,
                        collapsedHeight: 76,
                        backgroundColor: appBarColor,
                        automaticallyImplyLeading: false,
                        flexibleSpace: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 14),
                            child: RoomListSearchButton(
                                onUserTap: onAppBarClicked,
                                client: client,
                                onSelection: onSelection)),
                      ),
                    if (selectedSpace == CustomSpacesTypes.home)
                      SliverList(
                          delegate: SliverChildBuilderDelegate(
                              (context, i) => ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: StoriesList(client: client),
                                    ),
                                  ),
                              childCount: 1)),
                    if (presences != null)
                      SliverList(
                          delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) {
                        final presence = presences![index];
                        return RoomListItemPresence(
                            client: client,
                            presence: presence,
                            onTap: () {
                              final room = client
                                  .getDirectChatFromUserId(presence.userid);
                              onSelection(room ?? presence.userid);
                            });
                      }, childCount: presences.length)),
                    if (presences == null)
                      sortedRooms != null
                          ? SliverPadding(
                              padding: const EdgeInsets.only(bottom: 60),
                              sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                      (BuildContext context, int i) {
                                Room r = sortedRooms![i];
                                return RoomListItemSlidable(
                                    key: Key("room_${r.id}"),
                                    r: r,
                                    selectedRoomId: selectedRoomId,
                                    client: client,
                                    onSelection: onSelection);
                              }, childCount: sortedRooms!.length)),
                            )
                          : SliverList(
                              key: const Key("placeholder_list"),
                              delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int i) =>
                                    const MatrixRoomsListTileShimmer(),
                                childCount: 5,
                              ))
                  ],
                ),
        ),
      ],
    );
  }
}

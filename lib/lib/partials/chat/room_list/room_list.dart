import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/pages/chat_page_items/chat_page_spaces_list.dart';
import 'package:minestrix_chat/partials/chat/room_list/room_list_items/room_list_item.dart';

import '../../../pages/room_creator_page.dart';
import '../../dialogs/adaptative_dialogs.dart';
import '../spaces/list/spaces_list.dart';
import 'room_list_items/room_list_item_presence.dart';
import 'room_list_search_button.dart';

class RoomList extends StatefulWidget {
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
      required this.displaySpaceList,
      this.onAppBarClicked})
      : super(key: key);

  final Function(String?) onSelection;
  final String? selectedRoomId;
  final String? selectedSpace;
  final Client client;
  final List<Room>? sortedRooms;
  final ScrollController controller;
  final bool isMobile; // adapted for small screens
  final VoidCallback? onAppBarClicked;
  final bool displaySpaceList;

  @override
  State<RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<RoomList> {
  Set<String> selectedRooms = {};
  bool selectMode = false;

  final scrollControllerDrawer = ScrollController();

  void enableSelection() {
    if (!selectMode) {
      setState(() {
        selectMode = true;
      });
    }
  }

  void disableSelection() {
    setState(() {
      selectMode = false;
    });
    selectedRooms.clear();
  }

  void toggleElement(String roomId) {
    if (selectedRooms.contains(roomId)) {
      selectedRooms.remove(roomId);
      if (selectedRooms.isEmpty) selectMode = false;
    } else {
      selectedRooms.add(roomId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final isMobile = widget.isMobile;
    final selectedSpace = (widget.selectedSpace != ""
            ? widget.selectedSpace
            : CustomSpacesTypes.home) ??
        CustomSpacesTypes.home;
    final onAppBarClicked = widget.onAppBarClicked;
    final onSelection = widget.onSelection;
    final controller = widget.controller;

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
    final isHome = selectedSpace == CustomSpacesTypes.home;

    return Scaffold(
      floatingActionButton: isHome
          ? FloatingActionButton.extended(
              onPressed: () async {
                await AdaptativeDialogs.show(
                    context: context,
                    title: "New message",
                    builder: (_) => RoomCreatorPage(
                        client: client, onRoomSelected: onSelection));
              },
              label: const Text("Start chat"),
              icon: const Icon(Icons.message),
            )
          : null,
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: ChatPageSpaceList(
              mobile: true, scrollController: scrollControllerDrawer),
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<SyncStatusUpdate>(
              stream: client.onSyncStatus.stream,
              builder: (context, snap) {
                if (snap.hasData) {
                  if (snap.data!.status == SyncStatus.processing &&
                      ![null, 0, 1.0].contains(snap.data!.progress)) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child:
                          LinearProgressIndicator(value: snap.data!.progress!),
                    );
                  }
                }
                return Container();
              }),
          Expanded(
            child: widget.displaySpaceList
                ? ChatPageSpaceList(
                    mobile: isMobile,
                    scrollController: controller,
                  )
                : CustomScrollView(
                    cacheExtent: 400,
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: controller,
                    slivers: [
                      if (!isMobile || selectMode)
                        SliverAppBar(
                          key: const Key("room_list_title"),
                          pinned: true,
                          automaticallyImplyLeading: false,
                          forceElevated: !isMobile,
                          actions: selectMode
                              ? [
                                  IconButton(
                                      onPressed: disableSelection,
                                      icon: const Icon(Icons.close))
                                ]
                              : [
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.folder),
                                    onPressed: () {},
                                  ),
                                ],
                          leading:
                              selectMode ? null : const Icon(Icons.message),
                          title: selectMode
                              ? const Text("Edit")
                              : const Text("Your chats"),
                        ),
                      if (selectMode == false)
                        isHome
                            ? SliverAppBar(
                                title: MobileSearchBar(
                                    onSelection: onSelection,
                                    client: client,
                                    onAppBarClicked: onAppBarClicked),
                                automaticallyImplyLeading: false,
                                forceElevated: !isMobile,
                              )
                            : Builder(builder: (context) {
                                final spaceRoom =
                                    client.getRoomById(selectedSpace);

                                String title = "";
                                if (selectedSpace.startsWith("!")) {
                                  title =
                                      "${spaceRoom?.getLocalizedDisplayname(const MatrixDefaultLocalizations())}";
                                } else if (selectedSpace ==
                                    CustomSpacesTypes.active) {
                                  title = "Active";
                                } else if (selectedSpace ==
                                    CustomSpacesTypes.dm) {
                                  title = "Direct message";
                                } else if (selectedSpace ==
                                    CustomSpacesTypes.favorites) {
                                  title = "Favorites";
                                } else if (selectedSpace ==
                                    CustomSpacesTypes.lowPriority) {
                                  title = "Low priority";
                                } else if (selectedSpace ==
                                    CustomSpacesTypes.unread) {
                                  title = "Unreads";
                                }
                                return SliverAppBar(
                                  key: const Key("space_title"),
                                  pinned: true,
                                  forceElevated: !isMobile,
                                  title: Text(title),
                                );
                              }),
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
                        widget.sortedRooms != null
                            ? SliverPadding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 60),
                                sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                        (BuildContext context, int i) {
                                  Room r = widget.sortedRooms![i];
                                  return RoomListItem(
                                    key: Key("room_${r.id}"),
                                    room: r,
                                    open: !isMobile &&
                                        r.id == widget.selectedRoomId,
                                    selected: selectedRooms.contains(r.id),
                                    client: widget.client,
                                    onSelection: (String text) {
                                      if (selectMode) {
                                        toggleElement(r.id);
                                      } else {
                                        widget.onSelection(text);
                                      }
                                    },
                                    onLongPress: () {
                                      selectedRooms.add(r.id);
                                      enableSelection();
                                    },
                                  );
                                }, childCount: widget.sortedRooms!.length)),
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
      ),
    );
  }
}

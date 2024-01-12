import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/pages/chat_lib/chat_page_items/chat_page_spaces_list.dart';
import 'package:minestrix/pages/chat_lib/chat_page_items/provider/chat_page_state.dart';
import 'package:minestrix/chat/partials/chat/room_list/room_list_items/room_list_item.dart';

import '../../../../pages/chat_lib/room_create/create_chat_page.dart';
import '../search/matrix_chats_search.dart';
import '../spaces/list/spaces_list.dart';
import 'room_list_explore.dart';
import 'room_list_items/room_list_item_presence.dart';

class RoomList extends StatefulWidget {
  ///  [allowPop]
  const RoomList(
      {super.key,
      required this.client,
      required this.scrollController,
      required this.sortedRooms,
      required this.isMobile,
      this.onAppBarClicked,
      required this.controller});

  final ChatPageState controller;

  final Client client;
  final List<Room>? sortedRooms;
  final ScrollController scrollController;
  final bool isMobile; // adapted for small screens
  final VoidCallback? onAppBarClicked;

  @override
  State<RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<RoomList> {
  bool spaceSelectionMode = false;

  Function(String?) get onSelection => (String? roomId) {
        widget.controller.selectRoom(roomId);
      };

  String? get selectedRoomId => widget.controller.selectedRoomID;
  String get selectedSpace {
    final id = widget.controller.selectedSpace;
    return id != "" ? id : CustomSpacesTypes.home;
  }

  Set<String> selectedRooms = {};
  bool selectMode = false;

  final scrollControllerDrawer = ScrollController();

  bool get isHome => selectedSpace == CustomSpacesTypes.home;

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
    final spaceRoom = client.getRoomById(selectedSpace);

    String title = selectedSpace;

    if (spaceRoom != null) {
      title = spaceRoom.getLocalizedDisplayname();
    }

    return Scaffold(
      floatingActionButton: isHome
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CreateChatPage(
                        client: client, onRoomSelected: onSelection)));
              },
              label: const Text("Start chat"),
              icon: const Icon(Icons.message),
            )
          : null,
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: ChatPageSpaceList(
              popAfterSelection: true,
              scrollController: scrollControllerDrawer),
        ),
      ),
      appBar: spaceSelectionMode
          ? AppBar(
              title: const Text("Space list"),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    spaceSelectionMode = false;
                  });
                },
              ),
            )
          : selectMode == true
              ? AppBar(actions: [
                  IconButton(
                      onPressed: disableSelection,
                      icon: const Icon(Icons.close))
                ], automaticallyImplyLeading: false, title: const Text("Edit"))
              : AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      setState(() {
                        spaceSelectionMode = true;
                      });
                    },
                  ),
                  title: Text(title),
                  actions: [
                    if (isHome)
                      IconButton(
                          onPressed: () async {
                            final id =
                                await MatrixChatsSearch.show(context, client);
                            if (id != null) {
                              widget.controller.selectRoom(id);
                            }
                          },
                          icon: const Icon(Icons.search)),
                    if (spaceRoom != null)
                      IconButton(
                          onPressed: () {
                            widget.controller.onLongPressedSpace(selectedSpace);
                          },
                          icon: const Icon(Icons.info))
                  ],
                ),
      body: spaceSelectionMode
          ? ChatPageSpaceList(
              onSelection: () {
                setState(() {
                  spaceSelectionMode = false;
                });
              },
              popAfterSelection: false,
              scrollController: scrollControllerDrawer)
          : Column(
              children: [
                StreamBuilder<SyncStatusUpdate>(
                    stream: client.onSyncStatus.stream,
                    builder: (context, snap) {
                      if (snap.hasData) {
                        if (snap.data!.status == SyncStatus.processing &&
                            ![null, 0, 1.0].contains(snap.data!.progress)) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: LinearProgressIndicator(
                                value: snap.data!.progress!),
                          );
                        }
                      }
                      return Container();
                    }),
                Expanded(
                  child: selectedSpace == CustomSpacesTypes.explore
                      ? RoomListExplore(
                          onSelect: (String roomId) {
                            widget.controller.selectRoom(roomId);
                          },
                        )
                      : widget.controller.displaySpaceList
                          ? ChatPageSpaceList(
                              popAfterSelection: isMobile,
                              scrollController: widget.scrollController,
                            )
                          : CustomScrollView(
                              cacheExtent: 400,
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: widget.scrollController,
                              slivers: [
                                if (presences != null)
                                  SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                          (BuildContext context, int index) {
                                    final presence = presences![index];
                                    return RoomListItemPresence(
                                        client: client,
                                        presence: presence,
                                        onTap: () {
                                          final room =
                                              client.getDirectChatFromUserId(
                                                  presence.userid);
                                          onSelection(room ?? presence.userid);
                                        });
                                  }, childCount: presences.length)),
                                if (presences == null)
                                  widget.sortedRooms != null
                                      ? widget.sortedRooms!.isEmpty
                                          ? SliverList(
                                              key:
                                                  const Key("placeholder_list"),
                                              delegate:
                                                  SliverChildBuilderDelegate(
                                                (BuildContext context, int i) =>
                                                    Center(
                                                        child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 80.0),
                                                  child: Column(
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .message_outlined,
                                                          size: 60),
                                                      const SizedBox(
                                                        height: 30,
                                                      ),
                                                      Text(
                                                        "No rooms",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge,
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                                childCount: 1,
                                              ))
                                          : SliverPadding(
                                              padding: const EdgeInsets.only(
                                                  top: 8, bottom: 60),
                                              sliver: SliverList(
                                                  delegate:
                                                      SliverChildBuilderDelegate(
                                                          (BuildContext context,
                                                              int i) {
                                                Room r = widget.sortedRooms![i];
                                                return RoomListItem(
                                                  key: Key("room_${r.id}"),
                                                  room: r,
                                                  open: !isMobile &&
                                                      r.id == selectedRoomId,
                                                  selected: selectedRooms
                                                      .contains(r.id),
                                                  client: widget.client,
                                                  onSelection: (String text) {
                                                    if (selectMode) {
                                                      toggleElement(r.id);
                                                    } else {
                                                      onSelection(text);
                                                    }
                                                  },
                                                  onLongPress: () {
                                                    selectedRooms.add(r.id);
                                                    enableSelection();
                                                  },
                                                );
                                              },
                                                          childCount: widget
                                                              .sortedRooms!
                                                              .length)),
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

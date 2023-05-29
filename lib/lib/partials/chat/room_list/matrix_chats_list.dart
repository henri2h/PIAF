import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/chat/room_list/matrix_rooms_list_tile.dart';
import 'package:minestrix_chat/partials/chat/room_list/matrix_rooms_list_title.dart';
import 'package:minestrix_chat/partials/stories/stories_list.dart';

import '../spaces_list/spaces_list.dart';
import 'chat_search_button.dart';
import 'matrix_user_presence_list_tile.dart';

class MatrixChatsList extends StatelessWidget {
  ///  [allowPop]
  const MatrixChatsList(
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: ChatsSearchButton(
              client: client,
              onSelection: onSelection,
              onUserTap: onAppBarClicked,
            ),
          ),
        Expanded(
          child: CustomScrollView(
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
                                          ![null, 0, 1.0]
                                              .contains(snap.data!.progress)) {
                                        return LinearProgressIndicator(
                                            value: snap.data!.progress!);
                                      }
                                    }
                                    return Container();
                                  }),
                            ),
                            MatrixRoomsListTitle(
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
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                      child: ChatsSearchButton(
                          onUserTap: onAppBarClicked,
                          client: client,
                          onSelection: onSelection)),
                ),
              if (selectedSpace == CustomSpacesTypes.home)
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (context, i) => ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: StoriesList(client: client),
                              ),
                            ),
                        childCount: 1)),
              if (presences != null)
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                  final presence = presences![index];
                  return UserPresenceListTile(
                      client: client,
                      presence: presence,
                      onTap: () {
                        final room =
                            client.getDirectChatFromUserId(presence.userid);
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
                          return SlidableMatrixRoomsListTile(
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

class SlidableMatrixRoomsListTile extends StatefulWidget {
  const SlidableMatrixRoomsListTile({
    Key? key,
    required this.r,
    required this.selectedRoomId,
    required this.client,
    required this.onSelection,
  }) : super(key: key);

  final Room r;
  final String? selectedRoomId;
  final Client client;
  final Function(String?) onSelection;

  @override
  SlidableMatrixRoomsListTileState createState() =>
      SlidableMatrixRoomsListTileState();
}

class SlidableMatrixRoomsListTileState
    extends State<SlidableMatrixRoomsListTile> {
  Future<void> toggleLowPriority() async {
    await widget.r.setLowPriority(!widget.r.isLowPriority);
  }

  bool get unmuted => widget.r.pushRuleState == PushRuleState.notify;

  Future<void> toggleNotification() async {
    await widget.r.setPushRuleState(
        unmuted ? PushRuleState.mentionsOnly : PushRuleState.notify);
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              await widget.r.setFavourite(!widget.r.isFavourite);
            },
            backgroundColor: widget.r.isFavourite ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            icon: widget.r.isFavourite ? Icons.favorite : Icons.favorite,
            label: widget.r.isFavourite ? 'Favourite' : 'Normal',
          ),
          SlidableAction(
            onPressed: (context) async {
              await toggleLowPriority();
            },
            backgroundColor:
                !widget.r.isLowPriority ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
            icon: widget.r.isLowPriority ? Icons.low_priority : Icons.list,
            label: widget.r.isLowPriority ? 'Low priority' : 'Normal priority',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
              onPressed: (context) async {
                await toggleNotification();
              },
              backgroundColor: unmuted ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
              icon: unmuted
                  ? Icons.notifications_outlined
                  : Icons.notifications_off_outlined,
              label: unmuted ? 'On' : 'Muted'),
          SlidableAction(
              onPressed: (context) async {
                await widget.r.leave();
                widget.onSelection(null);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Leave room'),
        ],
      ),
      child: MatrixRoomsListTile(
          key: Key("room_${widget.r.id}"),
          room: widget.r,
          selected: widget.r.id == widget.selectedRoomId,
          client: widget.client,
          onSelection: widget.onSelection),
    );
  }
}

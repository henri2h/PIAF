import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/chat/spaces/list/spaces_list.dart';
import 'package:minestrix_chat/utils/client_information.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../../config/matrix_types.dart';

class ChatPageState with ChangeNotifier {
  final Client client;
  final BuildContext context;
  final void Function(String?)? onRoomSelection;
  final void Function(String)? onSpaceSelection;
  final void Function(String?) onLongPressedSpace;

  String? selectedRoomID;
  String selectedSpace;

  bool displaySpaceList = false;

  bool spaceListExpanded = true;

  ChatPageState(
      {required this.client,
      required this.onRoomSelection,
      required this.onSpaceSelection,
      required this.onLongPressedSpace,
      required this.context,
      this.selectedSpace = CustomSpacesTypes.home}) {
    // close the chat view if we leave the room
    client.onSync.stream.where((up) => up.hasRoomUpdate).listen(onRoomSync);
  }

  void onRoomSync(SyncUpdate update) {
    if (selectedRoomID != null) {
      if (update.rooms?.leave?.containsKey(selectedRoomID) == true) {
        print("You left the room $selectedRoomID");
        //  selectRoom(null);
      }
    }
  }

  void getSpaceChildRec(Room room, Set<Room> rooms) {
    if (!room.isSpace) return;

    final uList = room.getParticipants();
    // TODO: we may not have all the participants

    for (final user in uList) {
      final roomId = client.getDirectChatFromUserId(user.id);

      if (roomId != null) {
        final room = client.getRoomById(roomId);

        if (room != null) {
          rooms.add(room);
        }
      }
    }

    for (final child in room.spaceChildren) {
      if (child.roomId != null) {
        final rChild = client.getRoomById(child.roomId!);
        if (rChild != null) {
          rooms.add(rChild);

          if (rChild.isSpace) {
            getSpaceChildRec(rChild, rooms);
          }
        }
      }
    }
  }

  void toggleSpaceList() {
    spaceListExpanded = !spaceListExpanded;

    notifyListeners();
  }

  void toggleDisplaySpaceList() {
    displaySpaceList = !displaySpaceList;
    notifyListeners();
  }

  /// Select a space, update the room list state and if [triggerCall]
  /// it will trigger the space selection.
  void selectSpace(String? id, {bool triggerCall = false}) {
    selectedSpace = id ?? CustomSpacesTypes.home;

    if (triggerCall) {
      onSpaceSelection?.call(selectedSpace);
    }

    notifyListeners();
  }

  Set<Room> getSpaceChilds(String id) {
    final room = client.getRoomById(id);
    if (room == null || !room.isSpace) return <Room>{};
    Set<Room> rooms = <Room>{};

    getSpaceChildRec(room, rooms);
    return rooms;
  }

  static const List<String> ignoredRoomTypes = [
    "m.space",
    StoriesExtension.storiesRoomType,
    MatrixTypes.account
  ];

  /// Filter rooms based on type and sort them according to last envent timestamp
  List<Room> getRoomList(Client client) {
    final start = DateTime.now();

    List<Room> rooms = client.rooms;

    if (selectedSpace.startsWith("!") == true) {
      rooms = getSpaceChilds(selectedSpace).toList();
    }

    List<Room> sortedRooms = rooms.where((Room r) {
      // When the don't have selected the low priority filter, we ignore then
      if ([CustomSpacesTypes.home, CustomSpacesTypes.favorites]
              .contains(selectedSpace) &&
          r.isLowPriority) {
        return false;
      }

      if (selectedSpace == CustomSpacesTypes.dm) {
        return r.isDirectChat;
      }

      // When we have selected the loo priority filter, we display only the low priority room
      if (selectedSpace == CustomSpacesTypes.lowPriority && !r.isLowPriority) {
        return false;
      }

      if (selectedSpace == CustomSpacesTypes.favorites && !r.isFavourite) {
        return false;
      }

      if (selectedSpace == CustomSpacesTypes.unread && !r.isUnreadOrInvited) {
        return false;
      }

      if (ignoredRoomTypes.contains(r.type)) {
        return false;
      }

      return true;

      //return !r.isSpace;
    }).toList();

    sortedRooms.sort((Room a, Room b) {
      if (a.lastEvent == null || b.lastEvent == null) {
        return 1; // we can't do anything here..., we just throw this conversation at the end
      }
      return b.lastEvent!.originServerTs.compareTo(a.lastEvent!.originServerTs);
    });

    final duration = DateTime.now().difference(start).inMilliseconds;
    Logs().i("Sorting room list took $duration milliseconds");

    return sortedRooms.toList();
  }

  void selectRoom(String? roomId) {
    selectedRoomID = roomId;
    if (roomId != null) Matrix.of(context).client.increaseLastOpened(roomId);
    onRoomSelection?.call(roomId);

    notifyListeners();
  }
}

// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class RoomListTitle extends StatelessWidget {
  const RoomListTitle(
      {Key? key,
      required this.client,
      required this.onRoomSelected,
      required this.allowPop,
      this.selectedSpace,
      this.onTap,
      this.mobile = false})
      : super(key: key);

  final Client client;
  final Function(String?) onRoomSelected;

  final VoidCallback? onTap;
  final bool allowPop;
  final bool mobile;
  final String? selectedSpace;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (mobile && Navigator.of(context).canPop() && allowPop)
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: () {
              onRoomSelected(null);
              Navigator.of(context).pop();
            },
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Builder(builder: (context) {
              Room? room;
              if (selectedSpace != null) {
                room = client.getRoomById(selectedSpace!);
              }
              return Text(room?.name ?? "Chats",
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold));
            }),
          ),
        ),
      ],
    );
  }
}

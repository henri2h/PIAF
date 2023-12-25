import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../matrix/matrix_image_avatar.dart';

class SpaceRoomSelection extends StatefulWidget {
  const SpaceRoomSelection({super.key, required this.client});

  final Client client;

  @override
  State<SpaceRoomSelection> createState() => _SpaceRoomSelectionState();
}

class _SpaceRoomSelectionState extends State<SpaceRoomSelection> {
  final selectedRooms = <String>{};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.client.rooms.length,
        itemBuilder: (context, index) {
          final room = widget.client.rooms[index];
          return CheckboxListTile(
            secondary: MatrixImageAvatar(
                client: room.client,
                url: room.avatar,
                defaultText: room.getLocalizedDisplayname()),
            title: Text(room.getLocalizedDisplayname()),
            onChanged: (bool? value) {
              if (!selectedRooms.add(room.id)) {
                selectedRooms.remove(room.id);
              }
              setState(() {});
            },
            value: selectedRooms.contains(room.id),
          );
        });
  }
}

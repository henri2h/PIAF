import 'package:flutter/material.dart';

import '../../../../partials/matrix/matrix_image_avatar.dart';
import '../../../../utils/matrix_widget.dart';

class SpaceRoomSelection extends StatefulWidget {
  const SpaceRoomSelection({super.key});

  @override
  State<SpaceRoomSelection> createState() => _SpaceRoomSelectionState();
}

class _SpaceRoomSelectionState extends State<SpaceRoomSelection> {
  final selectedRooms = <String>{};

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return ListView.builder(
        itemCount: client.rooms.length,
        itemBuilder: (context, index) {
          final room = client.rooms[index];
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

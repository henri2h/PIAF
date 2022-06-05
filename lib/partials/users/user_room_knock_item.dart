import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/style/minestrix_avatar_size_constants.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../components/buttons/customFutureButton.dart';

class UserRoomKnockItem extends StatelessWidget {
  const UserRoomKnockItem({
    Key? key,
    required this.user,
    required this.room,
  }) : super(key: key);

  final User user;
  final Room room;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MatrixImageAvatar(
          client: Matrix.of(context).client,
          url: user.avatarUrl,
          defaultText: user.displayName,
          width: MinestrixAvatarSizeConstants.small,
          height: MinestrixAvatarSizeConstants.small,
          backgroundColor: Theme.of(context).primaryColor,
          defaultIcon: Icon(Icons.person,
              color: Theme.of(context).colorScheme.onPrimary, size: 70),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(user.displayName ?? user.id,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Row(
                children: [
                  Flexible(
                    child: CustomFutureButton(
                      expanded: false,
                      color: Theme.of(context).primaryColor,
                      padding: EdgeInsets.all(2),
                      icon: Icon(Icons.check,
                          size: 15,
                          color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: () async {
                        await room.invite(user.id);
                      },
                      children: [
                        Text("Accept",
                            style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onPrimary))
                      ],
                    ),
                  ),
                  Flexible(
                    child: CustomFutureButton(
                      expanded: false,
                      padding: EdgeInsets.all(2),
                      icon: Icon(Icons.close, size: 15),
                      onPressed: () async {
                        await room.kick(user.id);
                      },
                      children: [
                        Text("Remove", style: TextStyle(fontSize: 15))
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

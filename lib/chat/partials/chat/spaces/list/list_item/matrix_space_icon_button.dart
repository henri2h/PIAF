import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:minestrix/chat/partials/matrix/matrix_image_avatar.dart';

class MatrixSpaceIconButton extends StatelessWidget {
  const MatrixSpaceIconButton(
      {super.key,
      required this.name,
      required this.id,
      required this.selectedSpace,
      this.avatarUrl,
      this.icon,
      required this.client,
      required this.onPressed,
      required this.onLongPressed,
      this.expanded = false,
      this.room});

  final String? id;
  final Room? room;
  final bool expanded;
  final String? selectedSpace;

  bool get selected => id == selectedSpace;

  /// name is used in the case where we want to display the all chat or low priority buttons
  final String name;
  final Uri? avatarUrl;
  final IconData? icon;

  final Client client;
  final void Function(String? id)? onPressed;
  final void Function(String? id)? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: MaterialButton(
          minWidth: 0,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          color: selected ? Theme.of(context).highlightColor : null,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onPressed: () => onPressed?.call(id),
          onLongPress: () => onLongPressed?.call(id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
            child: Row(
              children: [
                MatrixImageAvatar(
                    url: avatarUrl,
                    fit: true,
                    height: MinestrixAvatarSizeConstants.extraSmall,
                    width: MinestrixAvatarSizeConstants.extraSmall,
                    defaultIcon: Icon(icon),
                    defaultText: icon == null ? name : null,
                    client: client,
                    shape: MatrixImageAvatarShape.rounded),
                if (expanded)
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (room != null &&
                            room?.membership == Membership.invite)
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: MaterialButton(
                                color: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text("Join",
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary)),
                                onPressed: () async {
                                  await room!.join();
                                }),
                          )
                      ],
                    ),
                  ))
              ],
            ),
          )),
    );
  }
}

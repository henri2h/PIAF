import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';

import '../../../style/constants.dart';

class MatrixRoomTitle extends StatelessWidget {
  final Room? room;
  final String? userId;
  final Client client;
  final bool updating;
  final VoidCallback? onBack;
  final VoidCallback? onToggleSettings;
  final double height;

  const MatrixRoomTitle(
      {super.key,
      required this.room,
      required this.client,
      required this.height,
      this.userId,
      this.updating = false,
      this.onBack,
      this.onToggleSettings});

  @override
  Widget build(BuildContext context) {
    if (room != null) {
      return AppBar(
        forceMaterialTransparency: true,
        leading: onBack != null
            ? IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back))
            : null,
        title: MaterialButton(
          onPressed: onToggleSettings,
          child: Row(
            children: [
              MatrixImageAvatar(
                  url: room!.avatar,
                  defaultText: room!.displayname,
                  fit: true,
                  client: room!.client),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  room!.displayname,
                  style: Constants.kTextTitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (updating) const CircularProgressIndicator(),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: onToggleSettings,
          ),
        ],
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (room == null && userId?.startsWith("@") == true)
            Expanded(
              child: FutureBuilder<Profile>(
                  future: client.getProfileFromUserId(userId!),
                  builder: (context, snap) {
                    return Row(
                      children: [
                        MatrixImageAvatar(
                            url: snap.data?.avatarUrl,
                            defaultText: snap.data?.displayName,
                            fit: true,
                            client: client),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    snap.data?.displayName ?? userId!,
                                    style: Constants.kTextTitleStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
            ),
        ],
      ),
    );
  }
}

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
  final VoidCallback? onSearchPressed;
  final bool isMobile;
  final double height;

  const MatrixRoomTitle(
      {Key? key,
      required this.room,
      required this.client,
      required this.isMobile,
      required this.height,
      this.userId,
      this.updating = false,
      this.onBack,
      this.onSearchPressed,
      this.onToggleSettings})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onBack != null)
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          if (onBack == null)
            const SizedBox(
              width: 8,
            ),
          if (room != null)
            Expanded(
              child: SizedBox(
                height: height,
                child: MaterialButton(
                  onPressed: onToggleSettings,
                  child: Row(
                    children: [
                      MatrixImageAvatar(
                          url: room!.avatar,
                          defaultText: room!.displayname,
                          fit: true,
                          client: room!.client),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  room!.displayname,
                                  style: Constants.kTextTitleStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              if (updating) const CircularProgressIndicator(),
                              if (room?.encrypted == false)
                                IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: onSearchPressed,
                                ),
                              IconButton(
                                icon: const Icon(Icons.info),
                                onPressed: onToggleSettings,
                              ),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          if (room == null && userId?.isValidMatrixId == true)
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

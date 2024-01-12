import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/minestrix_chat.dart';
import 'package:minestrix/chat/partials/social/social_image_preview_widget.dart';

class SocialGalleryPreviewWigdet extends StatelessWidget {
  final Room room;
  final Timeline timeline;
  const SocialGalleryPreviewWigdet(
      {super.key, required this.room, required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          children: [
            for (Event e in timeline.getImages().take(4))
              SizedBox(
                height: 200,
                width: 200,
                child: SocialImagePreviewWidget(
                  e: e,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:minestrix/utils/platforms_info.dart';

class CustomEmojiPickerGrid extends StatelessWidget {
  const CustomEmojiPickerGrid({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 1200),
      child: EmojiPicker(
        config: Config(
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              // Issue: https://github.com/flutter/flutter/issues/28894
              emojiSizeMax: 28 * (PlatformInfos.isIOS ? 1.20 : 1.0),
            ),
            categoryViewConfig: const CategoryViewConfig(
                recentTabBehavior: RecentTabBehavior.NONE)),
        onEmojiSelected: (Category? category, Emoji? emoji) {
          Navigator.of(context).pop<Emoji>(emoji);
        },
      ),
    );
  }
}

class EmojiPopupRoute extends PopupRoute<Emoji> {
  EmojiPopupRoute();

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return const Align(
        alignment: Alignment.bottomCenter, child: CustomEmojiPickerGrid());
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);
}

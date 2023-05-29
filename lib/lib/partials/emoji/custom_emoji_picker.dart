import 'package:flutter/material.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class CustomEmojiPickerGrid extends StatelessWidget {
  const CustomEmojiPickerGrid({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 400),
      child: EmojiPicker(
        onEmojiSelected: (Category? category, Emoji? emoji) {
          Navigator.of(context).pop<Emoji>(emoji);
        },
        config: const Config(
          columns: 10,
        ),
      ),
    );
  }
}

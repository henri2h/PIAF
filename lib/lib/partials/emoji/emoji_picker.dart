import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';

class MinestrixEmojiPicker extends StatefulWidget {
  final double height;
  final double width;
  final String? selectedEmoji;
  final EdgeInsets? selectedEdge;

  final bool enableReply;
  final bool enableEdit;
  final bool enableDelete;

  const MinestrixEmojiPicker(
      {super.key,
      required this.height,
      required this.width,
      required this.selectedEmoji,
      required this.selectedEdge,
      this.enableReply = false,
      this.enableEdit = false,
      this.enableDelete = false});

  @override
  MinestrixEmojiPickerState createState() => MinestrixEmojiPickerState();
}

class MinestrixEmojiPickerState extends State<MinestrixEmojiPicker> {
  final bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.selectedEdge ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_open)
            Card(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MinestrixEmojiPickerItemEmoji("😄",
                      selected: widget.selectedEmoji),
                  MinestrixEmojiPickerItemEmoji("👍️",
                      selected: widget.selectedEmoji),
                  MinestrixEmojiPickerItemEmoji("❤️",
                      selected: widget.selectedEmoji),
                  MinestrixEmojiPickerItemEmoji("😇",
                      selected: widget.selectedEmoji),
                  MinestrixEmojiPickerItemIcon(
                    Icons.expand_circle_down,
                    selected: widget.selectedEmoji,
                    index: "+",
                  ),
                ],
              ),
            ),
          if (!_open && widget.enableReply)
            Card(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Column(
                  children: [
                    if (widget.enableReply)
                      const ListTile(
                        leading: Icon(Icons.reply),
                        title: Text("Reply"),
                      ),
                    if (widget.enableEdit)
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text("Edit"),
                        onTap: () {},
                      ),
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: const Text("Copy"),
                      onTap: () {},
                    ),
                    if (widget.enableDelete)
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {},
                      ),
                  ],
                ),
              ),
            )),
          if (_open)
            SizedBox(
              height: widget.height,
              width: widget.width,
              child: Material(
                child: EmojiPicker(
                  onEmojiSelected: (Category? category, Emoji? emoji) {
                    Navigator.of(context).pop<Emoji>(emoji);
                  },
                ),
              ),
            )
        ],
      ),
    );
  }
}

class EmjoiPickerRenderObject extends SingleChildRenderObjectWidget {
  final String index;

  const EmjoiPickerRenderObject(
      {required Widget super.child, required this.index, super.key});

  @override
  EmojiPickerRenderProxy createRenderObject(BuildContext context) {
    return EmojiPickerRenderProxy()..index = index;
  }

  @override
  void updateRenderObject(
      BuildContext context, EmojiPickerRenderProxy renderObject) {
    renderObject.index = index;
  }
}

class EmojiPickerRenderProxy extends RenderProxyBox {
  String index = "o";
}

// implementation
class MinestrixEmojiPickerItemEmoji extends StatelessWidget {
  final String emoji;
  final String? selected;

  const MinestrixEmojiPickerItemEmoji(this.emoji, {super.key, this.selected});

  @override
  Widget build(BuildContext context) {
    return MinestrixHoverPickerItem(
        builder: (bool isEmojiHovered) => Text(
              emoji,
              style: TextStyle(fontSize: isEmojiHovered ? 36 : 30),
            ),
        index: emoji,
        selected: selected);
  }
}

class MinestrixEmojiPickerItemIcon extends StatelessWidget {
  final IconData icon;
  final String index;
  final String? selected;
  final Color? color;

  const MinestrixEmojiPickerItemIcon(this.icon,
      {super.key, required this.index, this.selected, this.color});

  @override
  Widget build(BuildContext context) {
    return MinestrixHoverPickerItem(
        builder: (bool isEmojiHovered) =>
            Icon(icon, size: isEmojiHovered ? 36 : 30, color: color),
        index: index,
        selected: selected);
  }
}

// generic class
class MinestrixHoverPickerItem extends StatefulWidget {
  final String? selected;
  final Widget Function(bool isHovered) builder;
  final String index;

  const MinestrixHoverPickerItem(
      {super.key, required this.builder, required this.index, this.selected});

  @override
  MinestrixHoverPickerItemState createState() =>
      MinestrixHoverPickerItemState();
}

class MinestrixHoverPickerItemState extends State<MinestrixHoverPickerItem> {
  bool _isEmojiHovered = false;

  @override
  Widget build(BuildContext context) {
    _isEmojiHovered = widget.selected == widget.index;
    return EmjoiPickerRenderObject(
      index: widget.index,
      child: MouseRegion(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: widget.builder(_isEmojiHovered)),
        ),
        onEnter: (d) async {
          setState(() {
            _isEmojiHovered = true;
          });
          await HapticFeedback.heavyImpact();
        },
        onExit: (d) async {
          setState(() {
            _isEmojiHovered = false;
          });

          await HapticFeedback.heavyImpact();
        },
      ),
    );
  }
}

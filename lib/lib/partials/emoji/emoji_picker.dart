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
      {Key? key,
      required this.height,
      required this.width,
      required this.selectedEmoji,
      required this.selectedEdge,
      this.enableReply = false,
      this.enableEdit = false,
      this.enableDelete = false})
      : super(key: key);

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
            Row(
              children: [
                if (widget.enableReply)
                  Card(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MinestrixEmojiPickerItemIcon(
                          Icons.reply,
                          selected: widget.selectedEmoji,
                          index: "reply",
                        ),
                      ],
                    ),
                  ),
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
                if (widget.enableEdit || widget.enableDelete)
                  Card(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.enableEdit)
                          MinestrixEmojiPickerItemIcon(
                            Icons.edit,
                            selected: widget.selectedEmoji,
                            index: "edit",
                          ),
                        if (widget.enableDelete)
                          MinestrixEmojiPickerItemIcon(Icons.delete,
                              selected: widget.selectedEmoji,
                              index: "delete",
                              color: Colors.red),
                      ],
                    ),
                  ),
              ],
            ),
          if (_open)
            SizedBox(
              height: widget.height,
              width: widget.width,
              child: Material(
                child: EmojiPicker(
                  onEmojiSelected: (Category? category, Emoji? emoji) {
                    Navigator.of(context).pop<Emoji>(emoji);
                  },
                  config: const Config(
                    columns: 10,
                  ),
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
      {required Widget child, required this.index, Key? key})
      : super(child: child, key: key);

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

  const MinestrixEmojiPickerItemEmoji(this.emoji, {Key? key, this.selected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MinestrixHoverPickerItem(
        builder: (bool isEmojiHovered) => Text(
              emoji,
              style: TextStyle(fontSize: isEmojiHovered ? 26 : 22),
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
      {Key? key, required this.index, this.selected, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MinestrixHoverPickerItem(
        builder: (bool isEmojiHovered) =>
            Icon(icon, size: isEmojiHovered ? 26 : 22, color: color),
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
      {Key? key, required this.builder, required this.index, this.selected})
      : super(key: key);

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
          child: SizedBox(
              height: 34,
              width: 30,
              child: Center(child: widget.builder(_isEmojiHovered))),
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

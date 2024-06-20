import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:matrix/matrix.dart';

import 'emoji/custom_emoji_picker.dart';
import 'emoji/emoji_picker.dart';

/// A class to manage feed and manage reaction buttons
class CustomListViewWithEmoji extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int, void Function(Offset, Event))
      itemBuilder;
  final bool reverse;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  const CustomListViewWithEmoji(
      {super.key,
      required this.itemBuilder,
      required this.itemCount,
      this.physics,
      this.padding,
      this.reverse = false,
      this.controller});

  @override
  CustomListViewWithEmojiState createState() => CustomListViewWithEmojiState();
}

class CustomListViewWithEmojiState extends State<CustomListViewWithEmoji> {
  String? _selectedEmoji;
  Event? _selectedEvent;
  bool _emojiPickerDisplayed = false;
  EdgeInsets? _emojiPickerEdge;

  /// in order to detect when the distance between the cursor and the widget
  double _emojiItemHeight = 0;

  final GlobalKey key = GlobalKey();

  void _detectTapedItem(PointerEvent event, {bool isEventPointerDown = false}) {
    final RenderBox? box = key.currentContext!.findRenderObject() as RenderBox?;

    if (box != null) {
      final result = BoxHitTestResult();
      Offset offset = box.globalToLocal(event.position);

      if (box.hitTest(result, position: offset)) {
        for (final hit in result.path) {
          /// temporary variable so that the [is] allows access of [index]
          final target = hit.target;
          if (target is EmojiPickerRenderProxy) {
            EmojiPickerRenderProxy t = target;
            setState(() {
              _selectedEmoji = t.index;
            });
            _emojiItemHeight = event.position.dy;
            return;
          }
        }

        // hide emoji picker when the cursor leave the emoji picker and a emoji has been selected
        if (_selectedEmoji != null) {
          double verticalDistance = _emojiItemHeight - event.position.dy;
          if (verticalDistance < 0) verticalDistance = -verticalDistance;

          if (verticalDistance > 40) _clearSelection(null);
        }

        // for desktop, hide emoji picker when clicked on an other part of the screen
        if (isEventPointerDown && _emojiPickerDisplayed) {
          _clearSelection(null);
        }
      } else {
        if (_selectedEmoji != null) {
          _clearSelection(null);
        }
      }
    } else {
      _clearSelection(null);
    }
  }

  void _selectTapedItem(_) async {
    if (_selectedEmoji != null) {
      setState(() {
        _emojiPickerDisplayed = false;
      });

      if (_selectedEmoji == "+") {
        Logs().i("[ emoji ] : selected more");

        Emoji? emoji = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return const Dialog(child: CustomEmojiPickerGrid());
            });
        _selectedEmoji = emoji?.emoji;
      }

      if (_selectedEmoji != null && _selectedEvent != null) {
        await _selectedEvent!.room
            .sendReaction(_selectedEvent!.eventId, _selectedEmoji!);
      }

      _clearSelection(null);
    }
  }

  void _clearSelection(PointerUpEvent? event) {
    setState(() {
      _selectedEmoji = null;
      _selectedEvent = null;
      _emojiPickerDisplayed = false;
    });
  }

  void _onReact(Offset position, Event event) {
    _selectedEvent = event;

    final RenderBox? box = key.currentContext!.findRenderObject() as RenderBox?;

    if (box != null) {
      Offset offset = box.globalToLocal(position);

      double paddingLeft = offset.dx;
      double paddingTop =
          offset.dy + 22; // + 30 in order to be under the button

      double width = min(box.size.width, 400);
      double height = min(box.size.height, 180);

      if ((box.size.width - paddingLeft) < width) {
        paddingLeft = box.size.width - width;
      }
      if ((box.size.height - paddingTop) < height) {
        paddingTop = box.size.height - height;
      }
      setState(() {
        _emojiPickerDisplayed = true;
        _emojiPickerEdge = EdgeInsets.only(top: paddingTop, left: paddingLeft);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        _detectTapedItem(e, isEventPointerDown: true);
      },
      onPointerUp: _selectTapedItem,
      onPointerMove: _detectTapedItem,
      onPointerHover: _detectTapedItem,
      //onPointerUp: _clearSelection,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        key: key,
        children: [
          Align(
            alignment:
                widget.reverse ? Alignment.bottomCenter : Alignment.topCenter,
            child: ListView.builder(
                padding: widget.padding,
                shrinkWrap: true,
                controller: widget.controller,
                reverse: widget.reverse,
                cacheExtent: 8000,
                itemCount: widget.itemCount,
                physics: widget.physics ??
                    (_emojiPickerDisplayed
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics()),
                itemBuilder: (BuildContext c, int pos) =>
                    widget.itemBuilder(c, pos, _onReact)),
          ),
          if (_emojiPickerDisplayed)
            MinestrixEmojiPicker(
              width: 100,
              height: 100,
              selectedEmoji: _selectedEmoji,
              selectedEdge: _emojiPickerEdge,
            )
        ],
      ),
    );
  }
}

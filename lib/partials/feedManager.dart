import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/post/postView.dart';

/// A class to manage feed and manage reaction buttons
class FeedManager extends StatefulWidget {
  final List<Event> timeline;
  final Widget firstItem;
  const FeedManager({Key? key, required this.timeline, required this.firstItem})
      : super(key: key);

  @override
  _FeedManagerState createState() => _FeedManagerState();
}

class _FeedManagerState extends State<FeedManager> {
  ScrollController _controller = new ScrollController();

  String? _selectedEmoji;
  Event? _selectedEvent;
  bool _EmojiPickerDisplayed = false;
  EdgeInsets? _EmojiPickerEdge;

  /// in order to detect when the distance between the cursor and the widget
  double _EmojiItemHeight = 0;

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
            EmojiPickerRenderProxy _t = target;
            setState(() {
              _selectedEmoji = _t.index;
            });
            _EmojiItemHeight = event.position.dy;
            return;
          }
        }

        // hide emoji picker when the cursor leave the emoji picker and a emoji has been selected
        if (_selectedEmoji != null) {
          double vertical_distance = _EmojiItemHeight - event.position.dy;
          if (vertical_distance < 0) vertical_distance = -vertical_distance;
          print(vertical_distance.toString());
          if (vertical_distance > 40) _clearSelection(null);
        }

        // for desktop, hide emoji picker when clicked on an other part of the screen
        if (isEventPointerDown && _EmojiPickerDisplayed) {
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
    setState(() {
      _EmojiPickerDisplayed = false;
    });
    if (_selectedEmoji != null) {
      print("Selected : " + _selectedEmoji!);

      if (_selectedEmoji! == "+") {
        print("more selection");
      } else if (_selectedEmoji != null && _selectedEvent != null) {
        await _selectedEvent!.room
            .sendReaction(_selectedEvent!.eventId, _selectedEmoji!);
      }
    }

    _clearSelection(null);
  }

  void _clearSelection(PointerUpEvent? event) {
    setState(() {
      _selectedEmoji = null;
      _selectedEvent = null;
      _EmojiPickerDisplayed = false;
    });
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
          ListView.builder(
              shrinkWrap: true,
              controller: _controller,
              cacheExtent: 8000,
              itemCount: widget.timeline.length + 1,
              physics: _EmojiPickerDisplayed
                  ? NeverScrollableScrollPhysics()
                  : AlwaysScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int i) {
                if (i == 0) return widget.firstItem;
                if (widget.timeline.length >
                    0) // may be a redundant check... we never know
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    child: Post(
                        event: widget.timeline[i - 1],
                        onReact: (TapDownDetails detail) {
                          _selectedEvent = widget.timeline[i - 1];

                          final RenderBox? box = key.currentContext!
                              .findRenderObject() as RenderBox?;

                          if (box != null) {
                            Offset offset =
                                box.globalToLocal(detail.globalPosition);

                            double paddingLeft = offset.dx;
                            double paddingTop = offset.dy +
                                22; // + 30 in order to be under the button

                            double width = min(box.size.width, 400);
                            double height = min(box.size.height, 180);

                            if ((box.size.width - paddingLeft) < width)
                              paddingLeft = box.size.width - width;
                            if ((box.size.height - paddingTop) < height)
                              paddingTop = box.size.height - height;
                            setState(() {
                              _EmojiPickerDisplayed = true;
                              _EmojiPickerEdge = EdgeInsets.only(
                                  top: paddingTop, left: paddingLeft);
                            });
                          }
                        }),
                  );
                else
                  return Text("Empty");
              }),
          if (_EmojiPickerDisplayed)
            MinestrixEmojiPicker(
              width: 100,
              height: 100,
              selectedEmoji: _selectedEmoji,
              selectedEdge: _EmojiPickerEdge,
            )
        ],
      ),
    );
  }
}

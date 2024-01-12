import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/services.dart';
import 'package:infinite_list/infinite_list.dart';
import 'package:matrix/matrix.dart';

import 'emoji/custom_emoji_picker.dart';
import 'emoji/emoji_picker.dart';

/// A class to manage feed and manage reaction buttons
class InfiniteCustomListViewWithEmoji extends StatefulWidget {
  final int itemCount;
  final Widget Function(
          BuildContext, int, ItemPositions, void Function(Offset, Event))
      itemBuilder;
  final bool reverse;
  final InfiniteListController controller;
  final EdgeInsets padding;
  final ScrollPhysics? physics;
  final double cacheExtent;

  const InfiniteCustomListViewWithEmoji(
      {super.key,
      required this.itemBuilder,
      required this.itemCount,
      this.physics,
      required this.padding,
      this.reverse = false,
      required this.controller,
      this.cacheExtent = 1000});

  @override
  InfiniteCustomListViewWithEmojiState createState() =>
      InfiniteCustomListViewWithEmojiState();
}

class InfiniteCustomListViewWithEmojiState
    extends State<InfiniteCustomListViewWithEmoji> {
  String? _selectedEmoji;
  Event? _selectedEvent;
  Event?
      _previousEvent; // in case of single tap, we need to hide the the box if we tap again on the message
  bool _emojiPickerDisplayed = false;
  EdgeInsets? _emojiPickerEdge;

  /// in order to detect when the distance between the cursor and the widget
  double _emojiItemHeight = 0;

  final GlobalKey key = GlobalKey();
  Future<void>? res;

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
            // did previously update?
            if (t.index != _selectedEmoji) {
              setState(() {
                _selectedEmoji = t.index;
              });

              res = HapticFeedback.heavyImpact();
              _emojiItemHeight = event.position.dy;
            }
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
          _previousEvent = _selectedEvent;
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
        Emoji? emoji = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return const Dialog(child: CustomEmojiPickerGrid());
            });
        _selectedEmoji = emoji?.emoji;
      }

      if (_selectedEmoji != null && _selectedEvent != null) {
        switch (_selectedEmoji) {
          case "reply":
          case "edit":
            break;
          case "delete":
            if (mounted) {
              final result = await showTextInputDialog(
                useRootNavigator: false,
                context: context,
                title: "Confirm removal",
                message:
                    "Are you sure you wish to remove (delete) this event? Note that if you delete a room name or topic change, it could undo the change.",
                okLabel: "Remove",
                textFields: [
                  const DialogTextField(
                      hintText: "Reason (optional)", initialText: "")
                ],
              );
              if (result?.isNotEmpty ?? false) {
                await _selectedEvent?.redactEvent(reason: result?.first);
              }
            }

            break;
          default:
            await _selectedEvent!.room
                .sendReaction(_selectedEvent!.eventId, _selectedEmoji!);
        }
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
    HapticFeedback.heavyImpact();

    if (_previousEvent == event && _previousEvent != null) {
      _previousEvent = null;
      return;
    }
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
            child: InfiniteListView(
              // shrinkWrap: true,
              padding: widget.padding,
              reverse: widget.reverse,
              cacheExtent: widget.cacheExtent,
              physics: widget.physics ??
                  (_emojiPickerDisplayed
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics()),
              itemBuilder:
                  (BuildContext c, int index, ItemPositions position) =>
                      widget.itemBuilder(c, index, position, _onReact),
              infiniteController: widget.controller,
            ),
          ),
          if (_emojiPickerDisplayed)
            MinestrixEmojiPicker(
              width: 100,
              height: 100,
              selectedEmoji: _selectedEmoji,
              selectedEdge: _emojiPickerEdge,
              enableDelete: (_selectedEvent?.canRedact ?? false) &&
                  !(_selectedEvent?.redacted ?? true),
              //enableEdit: _selectedEvent?.canRedact ?? false,
              //enableReply: true,
            )
        ],
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../event/matrix_image.dart';

class MatrixPostImageContainer extends StatefulWidget {
  const MatrixPostImageContainer(
      {super.key,
      required this.imageMaxHeight,
      required this.post,
      this.imageEvent,
      this.imageRef,
      required this.onPressed,
      this.text});
  final Function(Event, {Event? imageEvent, String? ref}) onPressed;
  final String? text;
  final double? imageMaxHeight;
  final Event post;
  final Event? imageEvent;
  final String? imageRef;

  @override
  State<MatrixPostImageContainer> createState() =>
      _MatrixPostImageContainerState();
}

class _MatrixPostImageContainerState extends State<MatrixPostImageContainer> {
  bool hovering = false;

  Event? get event => _event ?? widget.post;
  Event? _event;

  Future<Event?> getItem() async {
    if (widget.imageEvent != null) return widget.imageEvent;

    if (widget.imageRef != null) {
      return await widget.post.room.getEventById(widget.imageRef!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event?>(
        future: getItem(),
        builder: (context, snap) {
          if (!snap.hasData) return const CircularProgressIndicator();

          final image = snap.data;
          return FocusableActionDetector(
            onShowHoverHighlight: (value) {
              setState(() {
                hovering = value;
              });
            },
            child: MaterialButton(
              onPressed: () {
                widget.onPressed(widget.post,
                    imageEvent: widget.imageEvent, ref: widget.imageRef);
              },
              padding: const EdgeInsets.all(0),
              minWidth: 20,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (event != null && image != null)
                    MatrixImage(
                        key: Key(event!.eventId),
                        event: image,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.zero),
                  if (widget.text != null || hovering)
                    ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 1.0,
                          sigmaY: 1.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                              color: widget.text != null
                                  ? (hovering ? Colors.black38 : Colors.black12)
                                  : (hovering ? Colors.black12 : null)),
                        ),
                      ),
                    ),
                  if (widget.text != null)
                    Center(
                        child: Text(widget.text!,
                            style: const TextStyle(
                                fontSize: 64, color: Colors.white)))
                ],
              ),
            ),
          );
        });
  }
}

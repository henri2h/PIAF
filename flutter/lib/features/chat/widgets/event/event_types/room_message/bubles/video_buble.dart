import 'dart:math';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'message/matrix_video_message.dart';

class VideoBuble extends StatelessWidget {
  const VideoBuble({super.key, required this.event});

  final Event event;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: min<double>(MediaQuery.of(context).size.width * 0.6, 300),
          maxHeight: min<double>(MediaQuery.of(context).size.height * 0.4, 400),
        ),
        child: MatrixVideoMessage(event, key: Key("video_${event.eventId}")));
  }
}

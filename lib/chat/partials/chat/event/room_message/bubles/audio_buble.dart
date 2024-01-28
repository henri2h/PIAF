import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class AudioBuble extends StatelessWidget {
  const AudioBuble(
      {super.key,
      required this.event,
      required this.downloadAttachement,
      required this.foregroundColor,
      required this.backgroundColor});

  final Event event;
  final Color backgroundColor;
  final Color foregroundColor;
  final void Function() downloadAttachement;

  @override
  Widget build(BuildContext context) {
    return Card(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
              onTap: downloadAttachement,
              leading: Icon(Icons.audio_file, color: foregroundColor),
              title: Text("Audio", style: TextStyle(color: foregroundColor)),
              subtitle:
                  Text(event.body, style: TextStyle(color: foregroundColor))),
        ));
  }
}

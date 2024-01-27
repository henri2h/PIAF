import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class FileBuble extends StatelessWidget {
  const FileBuble(
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
              leading: Icon(Icons.file_present, color: foregroundColor),
              title: Text("File", style: TextStyle(color: foregroundColor)),
              subtitle: Text(event.body, style: TextStyle(color: foregroundColor))),
        ));
  }
}

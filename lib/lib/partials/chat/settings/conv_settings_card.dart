import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'conv_settings.dart';

class ConvSettingsCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onClose;
  const ConvSettingsCard({Key? key, required this.room, required this.onClose})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          color: Theme.of(context).cardColor,
          child: ConvSettings(room: room, onClose: onClose)),
    );
  }
}

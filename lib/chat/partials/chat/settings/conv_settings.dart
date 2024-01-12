import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../../../pages/chat_lib/room_settings_page.dart';

class ConvSettings extends StatefulWidget {
  final Room room;
  final VoidCallback? onClose;
  const ConvSettings({super.key, required this.room, required this.onClose});

  @override
  State<ConvSettings> createState() => _ConvSettingsState();
}

class _ConvSettingsState extends State<ConvSettings> {
  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return Navigator(
      onGenerateRoute: (route) => MaterialPageRoute(
        settings: route,
        builder: (context) => RoomSettingsPage(
            room: widget.room,
            onLeave: () {
              if (widget.onClose != null) {
                widget.onClose!();
                return;
              }

              if (mounted) {
                nav.pop();
              }
            }),
      ),
    );
  }
}

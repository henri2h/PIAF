import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import '../../../view/room_settings_page.dart';
import '../../dialogs/adaptative_dialogs.dart';

class ConvSettings extends StatefulWidget {
  final Room room;
  final VoidCallback? onClose;
  const ConvSettings({Key? key, required this.room, required this.onClose})
      : super(key: key);

  @override
  State<ConvSettings> createState() => _ConvSettingsState();
}

class _ConvSettingsState extends State<ConvSettings> {
  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return AdaptativeDialogsWidget(
      title: 'Settings',
      enableClose: true,
      onPressed: widget.onClose,
      maxHeight: double.infinity,
      child: Navigator(
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/chat/config/matrix_types.dart';
import 'package:minestrix/pages/chat_lib/room_settings_page.dart';
import 'package:minestrix/chat/partials/chat/settings/conv_settings_permissions.dart';

import '../components/minestrix/minestrix_title.dart';
import 'editor.dart';
import 'editor_join_rules_tile.dart';

class EditorSectionJoinRules extends StatelessWidget {
  const EditorSectionJoinRules(
      {super.key, required this.room, this.title, this.description});

  final Room room;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      text: "Join rules",
      children: [
        JoinRulesTile(
          room: room,
          icon: const Icon(Icons.post_add),
          permissionName: title ?? 'Permissions',
          permissionComment: description ?? 'Who can join the room',
        ),
      ],
    );
  }
}

class EditorSectionPermission extends StatelessWidget {
  const EditorSectionPermission({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      text: "Permissions",
      children: [
        PermissionTile(
          room: room,
          icon: const Icon(Icons.post_add),
          permissionName: 'Posting',
          permissionComment: 'Who can send posts',
          eventType: MatrixTypes.post,
        ),
        PermissionTile(
          room: room,
          icon: const Icon(Icons.comment),
          permissionName: 'Commenting',
          permissionComment: 'Who can comment on posts',
          eventType: MatrixTypes.comment,
        ),
      ],
    );
  }
}

class EditorSectionInfo extends StatelessWidget {
  const EditorSectionInfo({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      text: "Info",
      children: [
        EditorRoomName(room: room),
        EditorRoomTopic(room: room),
      ],
    );
  }
}

class EditorSectionOtherSettings extends StatelessWidget {
  const EditorSectionOtherSettings({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      text: "Other settings",
      children: [
        ListTile(
          title: const Text("Settings"),
          subtitle: const Text("Default room settings"),
          leading: const Icon(Icons.settings),
          trailing: const Icon(Icons.edit),
          onTap: () {
            RoomSettingsPage.show(context: context, room: room);
          },
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.children,
    required this.text,
  });

  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(top: 8.0, left: 8, right: 8, bottom: 8),
          child: H3Title(text),
        ),
        ...children
      ],
    );
  }
}

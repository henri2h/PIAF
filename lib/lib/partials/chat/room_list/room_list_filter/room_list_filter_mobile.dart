import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/pages/chat_page_items/provider/chat_page_provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../../../utils/matrix_widget.dart';
import '../../../dialogs/adaptative_dialogs.dart';
import '../../../matrix/matrix_image_avatar.dart';
import '../../spaces/list/spaces_list.dart';

class RoomListFilterMobile extends StatefulWidget {
  const RoomListFilterMobile({Key? key}) : super(key: key);

  static Future<void> show({required BuildContext context}) async {
    await AdaptativeDialogs.show(
      context: context,
      bottomSheet: true,
      title: 'Filter',
      builder: (context) => const RoomListFilterMobile(),
    );
  }

  @override
  RoomListFilterMobileState createState() => RoomListFilterMobileState();
}

class RoomListFilterMobileState extends State<RoomListFilterMobile> {
  @override
  Widget build(BuildContext context) {
    const checked = Icon(Icons.check);
    final client = Matrix.of(context).client;
    final rooms = client.rooms.where((room) => room.isSpace);

    final roomList = ChatPageProvider.of(context);

    return ListView(
      children: [
        SettingsList(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            lightTheme: const SettingsThemeData(
                settingsListBackground: Colors.transparent),
            darkTheme: const SettingsThemeData(
                settingsListBackground: Colors.transparent),
            sections: [
              SettingsSection(title: const Text("Filter by"), tiles: [
                SettingsTile.navigation(
                  title: const Text('All'),
                  leading: const Icon(Icons.home),
                  onPressed: (BuildContext context) {
                    roomList.selectSpace(CustomSpacesTypes.home);
                    Navigator.of(context).pop();
                  },
                ),
                SettingsTile.navigation(
                  title: const Text('Favorites'),
                  leading: const Icon(Icons.star),
                  onPressed: (BuildContext context) {
                    roomList.selectSpace(CustomSpacesTypes.favorites);
                    Navigator.of(context).pop();
                  },
                ),
                SettingsTile.navigation(
                  title: const Text('Unreads'),
                  leading: const Icon(Icons.notifications),
                  onPressed: (BuildContext context) {
                    roomList.selectSpace(CustomSpacesTypes.unread);
                    Navigator.of(context).pop();
                  },
                ),
                SettingsTile.navigation(
                  title: const Text('Active'),
                  leading: const Icon(Icons.person),
                  onPressed: (BuildContext context) {
                    roomList.selectSpace(CustomSpacesTypes.dm);
                    Navigator.of(context).pop();
                  },
                ),
                SettingsTile.navigation(
                  title: const Text('Direct message'),
                  leading: const Icon(Icons.people),
                  onPressed: (BuildContext context) {
                    roomList.selectSpace(CustomSpacesTypes.dm);
                    Navigator.of(context).pop();
                  },
                ),
                SettingsTile.navigation(
                  title: const Text('Low priority'),
                  leading: const Icon(Icons.notifications_off),
                  onPressed: (BuildContext context) {
                    roomList.selectSpace(CustomSpacesTypes.lowPriority);
                    Navigator.of(context).pop();
                  },
                ),
              ]),
              SettingsSection(title: const Text("Spaces"), tiles: [
                for (final room in rooms)
                  SettingsTile.navigation(
                    leading: Padding(
                      padding: const EdgeInsets.all(2),
                      child: MatrixImageAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        height: MinestrixAvatarSizeConstants.extraSmall,
                        width: MinestrixAvatarSizeConstants.extraSmall,
                        url: room.avatar,
                        client: client,
                        defaultText: room.name,
                        shape: MatrixImageAvatarShape.rounded,
                      ),
                    ),
                    title: Text(room.getLocalizedDisplayname(
                        const MatrixDefaultLocalizations())),
                    onPressed: (BuildContext context) {
                      roomList.selectSpace(room.id,
                          triggerCall: false); // don't navigate to space view
                      Navigator.of(context).pop();
                    },
                  ),
              ])
            ]),
      ],
    );
  }
}

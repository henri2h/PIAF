import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';
import 'package:minestrix/partials/components/minestrix/minestrix_title.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:settings_ui/settings_ui.dart';

import 'settings/settings_story_detail_page.dart';

@RoutePage()
class DebugPage extends StatefulWidget {
  const DebugPage({Key? key}) : super(key: key);

  @override
  DebugPageState createState() => DebugPageState();
}

class DebugPageState extends State<DebugPage> {
  List<int> timelineLength = [];
  List<Room> rooms = [];
  Client? client;
  bool init = false;
  bool progressing = false;

  void changeLogLevel(Level? level) {
    if (level != null) {
      setState(() {
        Logs().level = level;
      });
    }
  }

  void _clearCacheAndResync() async {
    final res = await showOkCancelAlertDialog(
        context: context,
        title: "Clear cache",
        message:
            "This will clear your cache and start a new sync to get your messages. This will take a long time. Are you sure ?",
        okLabel: "Yes");

    if (res != OkCancelResult.ok) {
      return;
    }

    if (client == null) return;
    Logs().w("Clearing cache");
    client!.clearCache();
    Logs().w("Sync done");
  }

  Future<void> loadElements(BuildContext context, Room room) async {
    setState(() {
      progressing = true;
    });

    Timeline? t = await room.getTimeline();

    await t.requestHistory();

    setState(() {
      progressing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    client = Matrix.of(context).client;

    rooms = client!.srooms;
    if (init == false) {
      init = true;
    }

    return ListView(children: [
      const CustomHeader(title: "Debug"),
      SettingsList(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          lightTheme: const SettingsThemeData(
              settingsListBackground: Colors.transparent),
          darkTheme: const SettingsThemeData(
              settingsListBackground: Colors.transparent),
          sections: [
            SettingsSection(title: const Text("Log level"), tiles: [
              SettingsTile(
                  title: const Text(
                      "Change the log level for this session. Settings will be cleared after restart.")),
              SettingsTileRadio.radio(
                  title: const Text("Debug"),
                  value: Level.debug,
                  groupValue: Logs().level,
                  onPressed: changeLogLevel),
              SettingsTileRadio.radio(
                  title: const Text("Verbose"),
                  value: Level.verbose,
                  groupValue: Logs().level,
                  onPressed: changeLogLevel),
              SettingsTileRadio.radio(
                  title: const Text("Info"),
                  value: Level.info,
                  groupValue: Logs().level,
                  onPressed: changeLogLevel),
              SettingsTileRadio.radio(
                  title: const Text("Warning"),
                  value: Level.warning,
                  groupValue: Logs().level,
                  onPressed: changeLogLevel),
              SettingsTileRadio.radio(
                  title: const Text("Error"),
                  value: Level.error,
                  groupValue: Logs().level,
                  onPressed: changeLogLevel),
            ]),
            SettingsSection(title: const Text("Info"), tiles: <SettingsTile>[
              SettingsTile(
                  title: const Text("Clear cache and resync"),
                  leading: const Icon(Icons.new_releases),
                  description: const Text(
                      "Use with caution, this make take a long time"),
                  trailing: const Icon(Icons.refresh),
                  onPressed: (context) => _clearCacheAndResync()),
            ]),
            SettingsSection(
                title: const Text("MinesTRIX rooms"),
                tiles: <SettingsTile>[
                  if (rooms.isNotEmpty)
                    for (var i = 0; i < rooms.length; i++)
                      SettingsTile(
                          title: Text(rooms[i].name),
                          description:
                              Text("creator: ${rooms[i].creator?.displayName}"),
                          leading: MatrixImageAvatar(
                            client: client,
                            url: rooms[i].avatar,
                            defaultText: rooms[i].getLocalizedDisplayname(),
                          ),
                          trailing: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                await loadElements(context, rooms[i]);
                              }))
                ]),
          ]),
      const H2Title("Minestrix rooms"),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Text("This is where the posts are stored."),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client != null)
              Text("MinesTRIX rooms length : ${client!.sroomsByUserId.length}"),
            if (progressing) const CircularProgressIndicator(),
          ],
        ),
      ),
    ]);
  }
}

class MainNavButton extends StatelessWidget {
  const MainNavButton({Key? key, required this.text, required this.builder})
      : super(key: key);

  final String text;
  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
          title: Text(text),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: builder));
          }),
    );
  }
}

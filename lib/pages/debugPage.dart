import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/customHeader.dart';
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_item.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';

class DebugPage extends StatefulWidget {
  @override
  _DebugPageState createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  List<int> timelineLength = [];
  List<Room> rooms = [];
  Client? client;
  bool init = false;
  bool progressing = false;

  void _clearCacheAndResync() async {
    Logs().w("Clearing cache");
    await client?.database?.clearCache();
    Logs().w("Sync");
    await client?.handleSync(await client!.sync());
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
      CustomHeader(title: "Debug"),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ElevatedButton(
                child: Text("Clear cache and resync"),
                onPressed: _clearCacheAndResync),
          ],
        ),
      ),
      const LogLevel(),
      H2Title("Minestrix rooms"),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text("This is where the posts are stored."),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rooms.length != 0)
              for (var i = 0; i < rooms.length; i++)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ListTile(
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(rooms[i].name),
                          ),
                          Text(" - " + rooms[i].id,
                              style: TextStyle(fontWeight: FontWeight.normal)),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: MatrixUserItem(
                                client: client,
                                name: rooms[i].creator?.displayName,
                                userId: rooms[i].creatorId ?? '',
                                avatarUrl: rooms[i].creator?.avatarUrl,
                              ),
                            ),
                          ],
                        ),
                      ),
                      leading: (timelineLength.length > i)
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(timelineLength[i].toString()),
                            )
                          : null,
                      trailing: IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () async {
                            await loadElements(context, rooms[i]);
                          })),
                ),
            if (client != null)
              Text("MinesTRIX rooms length : " +
                  client!.sroomsByUserId.length.toString()),
            if (progressing) CircularProgressIndicator(),
          ],
        ),
      ),
    ]);
  }
}

class LogLevel extends StatefulWidget {
  const LogLevel({Key? key}) : super(key: key);

  @override
  State<LogLevel> createState() => _LogLevelState();
}

class _LogLevelState extends State<LogLevel> {
  void changeLogLevel(Level? level) {
    if (level != null) {
      setState(() {
        Logs().level = level;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
            title: const Text("Log level"),
            subtitle: Text(
                "Change the log level for this session. Settings will be cleared after restart.")),
        RadioListTile(
            title: const Text("Debug"),
            subtitle: const Text("Hmm... so much noise"),
            value: Level.debug,
            groupValue: Logs().level,
            onChanged: changeLogLevel),
        RadioListTile(
            title: const Text("Verbose"),
            value: Level.verbose,
            groupValue: Logs().level,
            onChanged: changeLogLevel),
        RadioListTile(
            title: const Text("Info"),
            value: Level.info,
            groupValue: Logs().level,
            onChanged: changeLogLevel),
        RadioListTile(
            title: const Text("Warning"),
            value: Level.warning,
            groupValue: Logs().level,
            onChanged: changeLogLevel),
        RadioListTile(
            title: const Text("Error"),
            value: Level.error,
            groupValue: Logs().level,
            onChanged: changeLogLevel),
      ],
    );
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

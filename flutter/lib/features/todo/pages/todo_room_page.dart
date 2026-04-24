import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/router.gr.dart';
import '../../../utils/extensions/matrix/room_extension.dart';

import '../../../config/matrix_types.dart';
import '../../../partials/style/constants.dart';

@RoutePage()
class TodoRoomPage extends StatefulWidget {
  const TodoRoomPage({super.key, required this.room});

  final Room room;

  @override
  State<TodoRoomPage> createState() => _TodoRoomPageState();
}

class _TodoRoomPageState extends State<TodoRoomPage> {
  Future<Timeline>? _timeline;
  @override
  void initState() {
    _timeline = widget.room.getTimeline();
    super.initState();
  }

  final textController = TextEditingController();

  void send() async {
    final text = textController.text;
    textController.clear();
    await widget.room.sendEvent({"body": text}, type: EventTypes.Message);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Todo"),
          actions: [
            IconButton(
                onPressed: () async {
                  await context.pushRoute(RoomSettingsRoute(
                      room: widget.room,
                      onLeave: () {
                        if (context.mounted) {
                          context.maybePop();
                        }
                      }));
                },
                icon: Icon(Icons.info))
          ],
        ),
        body: FutureBuilder<Timeline>(
            future: _timeline,
            builder: (context, snapshot) {
              final timeline = snapshot.data;

              return Column(
                children: [
                  StreamBuilder<Object>(
                      stream: widget.room.onRoomInSync(),
                      builder: (context, snapshot) {
                        final events = (timeline?.events ?? [])
                            .where((event) =>
                                (event.type == MatrixTypes.todo ||
                                    event.type == EventTypes.Message) &&
                                !event.redacted)
                            .toList();

                        return Expanded(
                          child: ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[index];
                                return ListTile(
                                    title: Text(event.body),
                                    trailing: event.canRedact
                                        ? IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () async {
                                              await event.redactEvent(
                                                  reason: "done");
                                            })
                                        : null);
                              }),
                        );
                      }),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                            controller: textController,
                            decoration: Constants.kTextFieldInputDecoration
                                .copyWith(
                                    prefixIcon: Icon(Icons.title),
                                    hintText: "Title")),
                      ),
                      SizedBox(width: 8),
                      IconButton.filled(onPressed: send, icon: Icon(Icons.send))
                    ],
                  ),
                ],
              );
            }));
  }
}

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class DebugPage extends StatefulWidget {
  @override
  _DebugPageState createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Future<void> loadElements(BuildContext context, MinestrixRoom sroom) async {
    setState(() {
      progressing = true;
    });

    Timeline? t = sroom.timeline;
    if (t != null) {
      await t.requestHistory();
      await sclient!.loadNewTimeline();
      getTimelineLength();
    } else {
      print("error [debugVue] : timeline is null");
    }
    setState(() {
      progressing = false;
    });
  }

  void getTimelineLength() {
    timelineLength.clear();
    for (var i = 0; i < srooms.length; i++) {
      Timeline t = srooms[i].timeline!;

      timelineLength.add(t.events.length);
    }

    if (this.mounted)
      setState(() {
        print("State : " + timelineLength.length.toString());
      });
  }

  List<int> timelineLength = [];
  List<MinestrixRoom> srooms = [];
  MinestrixClient? sclient;
  bool init = false;

  bool progressing = false;
  @override
  Widget build(BuildContext context) {
    sclient = Matrix.of(context).sclient;

    srooms = sclient!.srooms.values.toList();
    if (init == false) {
      init = true;
      getTimelineLength();
    }

    return ListView(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            H1Title("Debug"),
            if (sclient != null && sclient!.rooms != null)
              Text("MinesTRIX rooms length : " +
                  sclient!.srooms.length.toString()),
            if (srooms.length != 0)
              for (var i = 0; i < srooms.length; i++)
                ListTile(
                    title: Text(srooms[i].room!.name),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, size: 16),
                              SizedBox(width: 10),
                              Text(srooms[i].user!.displayName!),
                            ],
                          ),
                          Text(srooms[i].room!.id),
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
                          await loadElements(context, srooms[i]);
                        })),
            if (progressing) CircularProgressIndicator(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                    child: Text("Load all more"),
                    onPressed: () async {
                      for (MinestrixRoom room in srooms) {
                        await loadElements(context, room);
                      }
                    }),
              ),
            )
          ],
        ),
      ),
    ]);
  }
}

import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrix/SMatrixRoom.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class DebugView extends StatefulWidget {
  @override
  _DebugViewState createState() => _DebugViewState();
}

class _DebugViewState extends State<DebugView> {
  Future<void> loadElements(BuildContext context, SMatrixRoom sroom) async {
    setState(() {
      progressing = true;
    });

    Timeline t = sroom?.timeline;
    if (t != null) {
      await t.requestHistory();
      await sclient.loadNewTimeline();
      getTimelineLength();
    } else {
      print("error");
    }
    setState(() {
      progressing = false;
    });
  }

  void getTimelineLength() {
    timelineLength.clear();
    for (var i = 0; i < srooms.length; i++) {
      Timeline t = srooms[i].timeline;

      timelineLength.add(t.events.length);
    }

    if (this.mounted)
      setState(() {
        print("State : " + timelineLength.length.toString());
      });
  }

  List<int> timelineLength = [];
  List<SMatrixRoom> srooms = [];
  SClient sclient;
  bool init = false;

  bool progressing = false;
  @override
  Widget build(BuildContext context) {
    sclient = Matrix.of(context).sclient;

    srooms = sclient.srooms.values.toList();
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
            if (sclient != null && sclient.rooms != null)
              Text("srooms length : " + sclient.srooms.length.toString()),
            if (srooms.length != 0)
              for (var i = 0; i < srooms.length; i++)
                ListTile(
                    title: Text(srooms[i].room.name),
                    subtitle: Text(srooms[i].room.id),
                    leading: (timelineLength.length > i)
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(timelineLength[i].toString()),
                          )
                        : null,
                    trailing: TextButton(
                        child: Text("Load"),
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
                      for (SMatrixRoom room in srooms) {
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

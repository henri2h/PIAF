import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class DebugView extends StatefulWidget {
  @override
  _DebugViewState createState() => _DebugViewState();
}

class _DebugViewState extends State<DebugView> {
  Future<void> loadElements(BuildContext context, SMatrixRoom sroom) async {
    Timeline t = await sroom.room.getTimeline();
    await t.requestHistory();
    await sclient.loadNewTimeline();
    await getTimelineLength();
  }

  Future<void> getTimelineLength() async {
    timelineLength.clear();
    for (var i = 0; i < srooms.length; i++) {
      Timeline t = await srooms[i].room.getTimeline();
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

  @override
  Widget build(BuildContext context) {
    sclient = Matrix.of(context).sclient;

    srooms = sclient.srooms;
    if (init == false) {
      init = true;
      getTimelineLength();
    }

    return Scaffold(
        appBar: AppBar(title: Text("Well... Debug time !!")),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text("Debug",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              if (sclient != null && sclient.rooms != null)
                Text("srooms length : " + sclient.srooms.length.toString()),
              if (srooms.length != 0)
                for (var i = 0; i < srooms.length; i++)
                  Row(
                    children: [
                      Text(i.toString()),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(srooms[i].room.name),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(srooms[i].room.id),
                      ),
                      if (timelineLength.length > i)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(timelineLength[i].toString()),
                        ),
                      RaisedButton(
                          child: Text("Load"),
                          onPressed: () async {
                            await loadElements(context, sclient.srooms[i]);
                          })
                    ],
                  ),
            ],
          ),
        ));
  }
}


import 'package:famedlysdk/famedlysdk.dart';
import 'package:famedlysdk/matrix_api/model/event_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:minestrix/components/minesTrix/MinesTrixThumbnailImage.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostHeader extends StatelessWidget {
  final Event event;
  const PostHeader({Key key, this.event}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              MinesTrixThumbnailImage(
                  url: event.sender.avatarUrl, width: 45, height: 45),
              SizedBox(width: 15),
              Flexible(
                child: FutureBuilder<String>(
                    future: sclient.getRoomDisplayName(event.room),
                    builder: (context, AsyncSnapshot<String> name) {
                      if (name.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.sender.displayName,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Text("to",
                                    style: TextStyle(color: Colors.grey[600])),
                                SizedBox(width: 2),
                                Text(name.data,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400)),
                              ],
                            ),
                            Text(timeago.format(event.originServerTs),
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey[600])),
                          ],
                        );
                      }
                      return Text(event.sender.displayName,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold));
                    }),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (event.type == EventTypes.Encrypted)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.enhanced_encryption),
                ),
              PopupMenuButton<String>(
                  itemBuilder: (_) => [
                        if (event.canRedact)
                          PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 10),
                                  Text("Edit post"),
                                ],
                              ),
                              value: "edit"),
                        if (event.canRedact)
                          PopupMenuItem(
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text("Delete post",
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              value: "delete")
                      ],
                  child: Icon(Icons.more_horiz),
                  onSelected: (String action) async {
                    switch (action) {
                      case "delete":
                        await event.redact();
                        break;
                      default:
                    }
                  })
            ],
          ),
        )
      ],
    );
  }
}

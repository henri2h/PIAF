import 'package:matrix/matrix.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/utils/helpers/NavigationHelper.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

class RightBar extends StatefulWidget {
  @override
  _RightBarState createState() => _RightBarState();
}

class _RightBarState extends State<RightBar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final sclient = Matrix.of(context).sclient;
    return StreamBuilder(
        stream: sclient.onSync.stream,
        builder: (context, _) => ListView.builder(
            itemCount: sclient.sfriends.values.length,
            itemBuilder: (BuildContext context, int i) =>
                ContactView(sroom: sclient.sfriends.values.toList()[i])));
  }
}

class ContactView extends StatelessWidget {
  const ContactView({
    Key key,
    @required this.sroom,
  }) : super(key: key);
  final MinestrixRoom sroom;
  @override
  Widget build(BuildContext context) {
    final MinestrixClient client = Matrix.of(context).sclient;
    if (sroom != null)
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: TextButton(
            onPressed: () {
              NavigationHelper.navigateToUserFeed(context, sroom.user);
            },
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              sroom.user == null || sroom.user.avatarUrl == null
                                  ? null
                                  : NetworkImage(
                                      sroom.user.avatarUrl
                                          .getThumbnail(
                                            client,
                                            width: 64,
                                            height: 64,
                                          )
                                          .toString(),
                                    ),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(sroom.user.displayName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                              .color)),
                                  Text(
                                    sroom.user.id,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .color),
                                  )
                                ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sroom.room.encrypted)
                    Icon(Icons.verified_user,
                        color: Theme.of(context).textTheme.bodyText1.color),
                  if (!sroom.room.encrypted)
                    Icon(Icons.no_encryption,
                        color: Theme.of(context).textTheme.bodyText1.color)
                ]),
          ),
        ),
      );
    return Text("ERROR !");
  }
}

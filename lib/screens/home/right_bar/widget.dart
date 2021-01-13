import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

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
            itemCount: sclient.srooms.values.length,
            itemBuilder: (BuildContext context, int i) =>
                ContactView(sroom: sclient.srooms.values.toList()[i])));
  }
}

class ContactView extends StatelessWidget {
  const ContactView({
    Key key,
    @required this.sroom,
  }) : super(key: key);
  final SMatrixRoom sroom;
  @override
  Widget build(BuildContext context) {
    final SClient client = Matrix.of(context).sclient;
    if (sroom != null)
      return SizedBox(
          child: Padding(
        padding: EdgeInsets.all(10.0),
        child: RaisedButton(
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          padding: EdgeInsets.all(20.0),
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
                                    sroom.user.avatarUrl.getThumbnail(
                                      client,
                                      width: 64,
                                      height: 64,
                                    ),
                                  ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(sroom.user.displayName,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  sroom.user.id,
                                  overflow: TextOverflow.ellipsis,
                                )
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (sroom.room.encrypted) Icon(Icons.verified_user),
                if (!sroom.room.encrypted) Icon(Icons.no_encryption)
              ]),
        ),
      ));
    return Text("ERROR !");
  }
}

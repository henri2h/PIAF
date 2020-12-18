import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/matrix.dart';
import 'package:minestrix/global/smatrix.dart';

class RightBar extends StatefulWidget {
  @override
  _RightBarState createState() => _RightBarState();
}

class _RightBarState extends State<RightBar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final sclient = Matrix.of(context).sclient;
    return StreamBuilder(
        stream: client.onSync.stream,
        builder: (context, _) => ListView.builder(
            itemCount: sclient.srooms.length,
            itemBuilder: (BuildContext context, int i) =>
                ContactView(sroom: sclient.srooms[i])));
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
    final Client client = Matrix.of(context).client;

      return SizedBox(
          child: Card(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
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
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(sroom.user.displayName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(sroom.user.id)
                                  ]),
                            ),
                          ],
                        ),
                        if (sroom.room.encrypted) Icon(Icons.verified_user),
                        if (!sroom.room.encrypted) Icon(Icons.no_encryption)
                      ]))));
   
  }
}
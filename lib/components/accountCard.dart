import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class AccountCard extends StatelessWidget {
  AccountCard({Key key, this.sroom}) : super(key: key);
  final SMatrixRoom sroom;
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundImage: sroom.user.avatarUrl == null
                  ? null
                  : NetworkImage(
                      sroom.user.avatarUrl.getThumbnail(
                        sclient,
                        width: 64,
                        height: 64,
                      ),
                    ),
            ),
            Text(sroom.user.displayName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Hello"),
          ],
        ),
      )),
    );
  }
}

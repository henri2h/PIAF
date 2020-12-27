import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class AccountCard extends StatelessWidget {
  AccountCard({Key key, this.user}) : super(key: key);
  final User user;
  @override
  Widget build(BuildContext context) {
    final SClient sclient = Matrix.of(context).sclient;

    return Card(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundImage: user.avatarUrl == null
                ? null
                : NetworkImage(
                    user.avatarUrl.getThumbnail(
                      sclient,
                      width: 64,
                      height: 64,
                    ),
                  ),
          ),
          Text(user.displayName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("Hello"),
        ],
      ),
    ));
  }
}

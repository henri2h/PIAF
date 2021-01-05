import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixThumbnailImage.dart';

class AccountCard extends StatelessWidget {
  AccountCard({Key key, this.user}) : super(key: key);
  final User user;
  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (user.avatarUrl == null)
            Text(user.displayName[0])
          else
            MinesTrixThumbnailImage(
                url: user.avatarUrl, width: 100, height: 100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
            child: Text(user.displayName,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

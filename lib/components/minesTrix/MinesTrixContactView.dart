import 'package:flutter/material.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';

class MinesTrixContactView extends StatelessWidget {
  const MinesTrixContactView({
    Key key,
    @required this.user,
  }) : super(key: key);
  final User user;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ]),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0)),
            padding: EdgeInsets.all(26.0),
          ),
          onPressed: () {
            NavigationHelper.navigateToUserFeed(context, user);
          },
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      MinesTrixUserImage(
                          url: user.avatarUrl,
                          width: 48,
                          thumnail: true,
                          height: 48),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(user.displayName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                Text(
                                  user.id,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.black),
                                )
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
                /*
                if (sroom.room.encrypted)
                  Icon(Icons.verified_user, color: Colors.black),
                if (!sroom.room.encrypted)
                  Icon(Icons.no_encryption, color: Colors.black)
                  */
              ]),
        ),
      ),
    );
  }
}

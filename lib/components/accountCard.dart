import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixUserImage.dart';
import 'package:minestrix/global/helpers/NavigationHelper.dart';

class AccountCard extends StatelessWidget {
  AccountCard({Key key, this.user}) : super(key: key);
  final User user;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        ),
        onPressed: () {
          NavigationHelper.navigateToUserFeed(context, user);
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              MinesTrixUserImage(
                url: user.avatarUrl,
                width: 100,
                height: 100,
                thumnail: true,
                defaultIcon: Icon(Icons.person, color: Colors.black, size: 70),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
                child: SizedBox(
                  width: 140,
                  height: 50,
                  child: Center(
                    child: Text(user.displayName,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

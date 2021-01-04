import 'package:cached_network_image/cached_network_image.dart';
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (user.avatarUrl == null)
            Text(user.displayName[0])
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: CachedNetworkImage(
                imageUrl: user.avatarUrl.getThumbnail(
                  sclient,
                  width: 300,
                  height: 300,
                ),
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    CircularProgressIndicator(value: downloadProgress.progress),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:0, vertical:3),
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

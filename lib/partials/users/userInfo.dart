import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix_chat/partials/matrix_user_image.dart';

class UserInfo extends StatelessWidget {
  const UserInfo({Key? key, this.user, this.profile, this.avatar})
      : super(key: key);

  final Profile? profile;
  final User? user;
  final Uri? avatar;

  @override
  Widget build(BuildContext context) {
    String? userId = user?.id;
    String? displayName = user?.displayName;
    Uri? avatarUrl = user?.avatarUrl;

    if (profile != null) {
      userId = profile!.userId;
      displayName = profile!.displayName;
      avatarUrl = profile!.avatarUrl;
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      // small screens
      if (constraints.maxWidth < 800)
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (avatar != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 180),
                child: CachedNetworkImage(imageUrl: avatar.toString()),
              ),
            buildUserProfileDisplay(
                context, avatarUrl, (displayName ?? userId!), userId!),
          ],
        );

      // big screens
      return Container(
          decoration: avatar != null
              ? BoxDecoration(
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(avatar.toString()),
                      fit: BoxFit.cover),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
            child: Align(
                alignment:
                    avatar != null ? Alignment.centerLeft : Alignment.center,
                child: buildUserProfileDisplay(
                    context, avatarUrl, (displayName ?? userId!), userId!)),
          ));
    });
  }

  Widget buildUserProfileDisplay(
      BuildContext context, Uri? avatarUrl, String displayName, String userId) {
    return Card(
      elevation: 15,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40.0),
        ),
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MatrixUserImage(
              client: Matrix.of(context).sclient,
              url: avatarUrl,
              width: 250,
              height: 250,
              thumnail: true,
              rounded: false,
              defaultIcon: Icon(Icons.person, size: 120),
            ),
            SizedBox(height: 10),
            Text(displayName,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            Text(userId,
                style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).textTheme.caption!.color)),
          ],
        ),
      ),
    );
  }
}

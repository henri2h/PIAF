import 'package:flutter/material.dart';
import 'package:minestrix/utils/matrixWidget.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';
import 'package:minestrix/utils/minestrix/minestrixRoom.dart';

import 'package:matrix_api_lite/src/generated/model.dart' as model;
import 'package:minestrix_chat/partials/matrix_user_image.dart';
import 'package:minestrix_chat/utils/room_feed_extension.dart';

class UserProfileSelection extends StatefulWidget {
  const UserProfileSelection(
      {Key? key,
      required this.userId,
      required this.onRoomSelected,
      required this.roomSelectedId})
      : super(key: key);
  final String userId;
  final String? roomSelectedId;
  final void Function(MinestrixRoom r) onRoomSelected;

  @override
  _UserProfileSelectionState createState() => _UserProfileSelectionState();
}

class _UserProfileSelectionState extends State<UserProfileSelection> {
  bool _creatingAccount = false;
  @override
  Widget build(BuildContext context) {
    MinestrixClient sclient = Matrix.of(context).sclient!;

    List<MinestrixRoom> _rooms = sclient.srooms.values
        .where((MinestrixRoom r) =>
            r.userID == widget.userId && r.type == FeedRoomType.user)
        .toList();

    if (_rooms.length > 1 || widget.userId == sclient.userID)
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (MinestrixRoom r in _rooms)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: MaterialButton(
                      color: r.room.id == widget.roomSelectedId
                          ? Colors.green
                          : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            MatrixUserImage(
                              client: sclient,
                              url: r.room.avatar,
                              thumnail: true,
                              defaultText: r.room.topic,
                              backgroundColor: Theme.of(context).primaryColor,
                              width: 45,
                              height: 45,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 100),
                              child: Text(r.room.topic,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.onRoomSelected(r);
                        });
                      }),
                ),
              if (widget.userId == sclient.userID)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: MaterialButton(
                    color: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          SizedBox(
                              height: 45,
                              child: _creatingAccount
                                  ? Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white),
                                    )
                                  : Icon(Icons.add, size: 36)),
                          SizedBox(
                            width: 8,
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 110),
                            child: Text("Create a new profile",
                                maxLines: 2,
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                          )
                        ],
                      ),
                    ),
                    onPressed: _creatingAccount
                        ? null
                        : () async {
                            setState(() {
                              _creatingAccount = true;
                            });
                            await sclient.createMinestrixAccount(
                                sclient.userID! + " timeline", "public account",
                                visibility: model.Visibility.public);
                            setState(() {
                              _creatingAccount = false;
                            });
                          },
                  ),
                )
            ],
          ),
        ),
      );

    return Container();
  }
}

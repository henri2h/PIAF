import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_api_lite/src/generated/model.dart' as model;
import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';
import 'package:minestrix/utils/matrix_widget.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
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
  final void Function(Room r) onRoomSelected;

  @override
  _UserProfileSelectionState createState() => _UserProfileSelectionState();
}

class _UserProfileSelectionState extends State<UserProfileSelection> {
  bool _creatingAccount = false;
  @override
  Widget build(BuildContext context) {
    Client sclient = Matrix.of(context).client;

    final _rooms = sclient.srooms
        .where((final r) =>
            r.userID == widget.userId && r.type == FeedRoomType.user)
        .toList();

    if (_rooms.length > 1 || widget.userId == sclient.userID) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            H2Title("User profiles"),
            for (final r in _rooms)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: MaterialButton(
                    color: r.id == widget.roomSelectedId
                        ? Theme.of(context).primaryColor
                        : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          MatrixImageAvatar(
                            client: sclient,
                            url: r.avatar,
                            thumnail: true,
                            defaultText: r.topic,
                            backgroundColor: Theme.of(context).primaryColor,
                            width: 45,
                            height: 45,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 100),
                            child: Text(r.topic,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: r.id == widget.roomSelectedId
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : null,
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: MaterialButton(
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
      );
    }

    return Container();
  }
}

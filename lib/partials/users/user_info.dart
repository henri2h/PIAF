import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/users/userAvatar.dart';
import 'package:minestrix_chat/partials/matrix/matrix_user_item.dart';
import 'package:minestrix_chat/utils/matrix/room_extension.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

class UserInfo extends StatelessWidget {
  const UserInfo({Key? key, this.room, this.profile})
      : assert(profile != null || room != null),
        super(key: key);

  final Profile? profile;
  final Room? room;

  Gradient noImageBoxDecoration(BuildContext context) => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Theme.of(context).primaryColor,
          Colors.grey.shade800,
        ],
      );

  @override
  Widget build(BuildContext context) {
    Client sclient = Matrix.of(context).client;
    String? roomUrl = room?.avatar
        ?.getThumbnail(sclient,
            width: 1000, height: 800, method: ThumbnailMethod.scale)
        .toString();
    User? u = room?.creator;
    Profile p = profile ??
        Profile(
            userId: u!.id, displayName: u.displayName, avatarUrl: u.avatarUrl);

    return Column(
      children: [
        LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          final smallScreen = constraints.maxWidth < 800;

          // big screens
          return Container(
              decoration: BoxDecoration(
                borderRadius: smallScreen ? null : BorderRadius.circular(8),
                image: roomUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(roomUrl),
                        fit: BoxFit.cover)
                    : null,
                gradient:
                    roomUrl != null ? null : noImageBoxDecoration(context),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20),
                child: Align(
                    alignment: smallScreen
                        ? Alignment.bottomCenter
                        : Alignment.centerLeft,
                    child: UserAvatar(p: p)),
              ));
        }),
      ],
    );
  }
}

class ClientChooser extends StatefulWidget {
  const ClientChooser({Key? key, required this.onUpdate}) : super(key: key);

  final VoidCallback onUpdate;
  @override
  State<ClientChooser> createState() => _ClientChooserState();
}

class _ClientChooserState extends State<ClientChooser> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<Client>(
      value: Matrix.of(context).client,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      underline: Container(),
      onChanged: (Client? c) {
        if (c != null) {
          setState(() {
            Matrix.of(context).setActiveClient(c);
          });

          widget.onUpdate();
        }
      },
      items: Matrix.of(context)
          .widget
          .clients
          .map<DropdownMenuItem<Client>>((Client client) {
        return DropdownMenuItem<Client>(
            value: client,
            child: SizedBox(
              width: 300,
              child: FutureBuilder<Profile>(
                  future: client.getProfileFromUserId(client.userID!),
                  builder: (context, snap) {
                    return MatrixUserItem(
                      name: snap.data?.displayName,
                      userId: client.userID!,
                      avatarUrl: snap.data?.avatarUrl,
                      client: client,
                    );
                  }),
            ));
      }).toList(),
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:piaf/chat/partials/matrix/matrix_image_avatar.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';

import '../pages/groups/create_group_page.dart';
import '../router.gr.dart';
import 'popup_route_wrapper.dart';

class AccountSelectionButton extends StatefulWidget {
  const AccountSelectionButton({super.key});

  @override
  State<AccountSelectionButton> createState() => _AccountSelectionButtonState();
}

class _AccountSelectionButtonState extends State<AccountSelectionButton> {
  final GlobalKey anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final client = Matrix.of(context).client;
      return IconButton(
        key: anchorKey,
        onPressed: () {
          Navigator.of(context).push(PopupRouteWrapper(
              anchorKeyContext: anchorKey.currentContext,
              builder: (rect) => AccountSelectionPopup(
                    position: rect,
                  )));
        },
        icon: FutureBuilder<Profile>(
            future: client.fetchOwnProfile(),
            builder: (context, snap) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: MatrixImageAvatar(
                  url: snap.data?.avatarUrl,
                  client: client,
                  defaultText: snap.data?.displayName ?? client.userID!,
                ),
              );
            }),
      );
    });
  }
}

class AccountSelectionPopup extends StatefulWidget {
  const AccountSelectionPopup({super.key, required this.position});
  final Rect position;
  @override
  State<AccountSelectionPopup> createState() => _AccountSelectionPopupState();
}

class _AccountSelectionPopupState extends State<AccountSelectionPopup> {
  Future<void> launchCreateGroupModal(BuildContext context) async {
    await AdaptativeDialogs.show(
        context: context, builder: (context) => const CreateGroupPage());
  }

  @override
  Widget build(BuildContext context) {
    final rect = widget.position;

    final m = Matrix.of(context);

    return Align(
        alignment: Alignment.topLeft,
        child: Transform.translate(
            offset: rect.topLeft,
            child: SizedBox(
              width: rect.width,
              height: rect.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text("Choose an account"),
                        ),
                        ListTile(
                            onTap: () async {
                              await context.navigateTo(UserViewRoute(
                                  userID: Matrix.of(context).client.userID));
                            },
                            title: const Text("My account"),
                            leading: const Icon(Icons.person)),
                        ListTile(
                            onTap: () {
                              launchCreateGroupModal(context);
                            },
                            leading: const Icon(Icons.group_add),
                            title: const Text("Create group")),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListView(
                                children: [
                                  for (final c in m.widget.clients)
                                    ListTile(
                                        title: Text(c.clientName),
                                        leading: FutureBuilder<Profile>(
                                            future: c.fetchOwnProfile(),
                                            builder: (context, snap) {
                                              return MatrixImageAvatar(
                                                url: snap.data?.avatarUrl,
                                                client: c,
                                                defaultText:
                                                    snap.data?.displayName,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                              );
                                            }),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(c.userID ?? ''),
                                          ],
                                        ),
                                        onTap: () async {
                                          m.setActiveClient(c);
                                          Navigator.of(context).pop();
                                        }),
                                  ListTile(
                                      title: const Text("Manage accounts"),
                                      trailing: const Icon(Icons.add),
                                      onTap: () async {
                                        await context.pushRoute(
                                            SettingsAccountSwitchRoute());
                                      }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text("Settings"),
                            onTap: () async {
                              context.popRoute();
                              context.pushRoute(const SettingsRoute());
                            }),
                      ],
                    ),
                  ),
                ),
              ),
            )));
  }
}

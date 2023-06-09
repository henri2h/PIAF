import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/components/fake_text_field.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../pages/minestrix/friends/research_page.dart';
import '../../pages/settings/settings_account_switch_page.dart';
import '../feed/notfication_bell.dart';

enum Selection { createPost, createStory }

class NavBarDesktop extends StatelessWidget {
  const NavBarDesktop({Key? key}) : super(key: key);

  void displaySearch(BuildContext context) async =>
      await AdaptativeDialogs.show(
          title: 'Search',
          builder: (context) => const ResearchPage(isPopup: true),
          context: context);
  Future<void> showUserSelection(BuildContext context) async {
    await AdaptativeDialogs.show(
        context: context,
        builder: (context) => const SettingsAccountSwitchPage(
              popOnUserSelected: true,
            ));
  }

  Future<void> launchCreatePostModal(BuildContext context) async {
    final client = Matrix.of(context).client;
    await AdaptativeDialogs.show(
        context: context,
        title: "Create post",
        builder: (BuildContext context) =>
            PostEditorPage(room: client.minestrixUserRoom));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16.0),
                child: Row(
                  children: [
                    Image.asset("assets/icon_512.png",
                        width: 40, height: 40, cacheHeight: 80, cacheWidth: 80),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("MinesTRIX",
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (constraints.maxWidth > 1000)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: FakeTextField(
                    icon: Icons.search,
                    onPressed: () => displaySearch(context),
                    text: "Search feeds and events",
                  ),
                ),
              ),
            ),
          Row(
            children: [
              if (constraints.maxWidth <= 1000)
                IconButton(
                    onPressed: () => displaySearch(context),
                    icon: const Icon(Icons.search)),
              PopupMenuButton<Selection>(
                  icon: const Icon(Icons.edit),
                  onSelected: (Selection selection) async {
                    switch (selection) {
                      case Selection.createPost:
                        await launchCreatePostModal(context);
                        break;
                      case Selection.createStory:
                        await Matrix.of(context)
                            .client
                            .openStoryEditModalOrCreate(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: Selection.createPost,
                            child: ListTile(
                                leading: Icon(Icons.post_add),
                                title: Text('Write post'))),
                        const PopupMenuItem(
                            value: Selection.createStory,
                            child: ListTile(
                                leading: Icon(Icons.camera_alt),
                                title: Text('Create a story'))),
                      ]),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: NotificationBell(),
              ),
              Builder(builder: (context) {
                final client = Matrix.of(context).client;
                return IconButton(
                  onPressed: () => showUserSelection(context),
                  icon: FutureBuilder<Profile>(
                      future: client.fetchOwnProfile(),
                      builder: (context, snap) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: MatrixImageAvatar(
                            url: snap.data?.avatarUrl,
                            client: client,
                            defaultText:
                                snap.data?.displayName ?? client.userID!,
                          ),
                        );
                      }),
                );
              }),
            ],
          ),
        ],
      );
    });
  }
}

class NavBarButton extends StatelessWidget {
  const NavBarButton({Key? key, this.name, this.icon, required this.onPressed})
      : super(key: key);
  final String? name;
  final IconData? icon;
  final Function onPressed;
  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed as void Function()?,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            if (name != null) const SizedBox(width: 6),
            if (name != null)
              Text(name!,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

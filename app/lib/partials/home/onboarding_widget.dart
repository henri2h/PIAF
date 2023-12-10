import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/models/search/search_mode.dart';
import 'package:minestrix/utils/minestrix/minestrix_client_extension.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/feed/posts/matrix_post_editor.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../pages/groups/create_group_page.dart';
import '../../router.gr.dart';
import 'welcome_actions_button.dart';

class OnboardingWidget extends StatelessWidget {
  const OnboardingWidget({
    super.key,
    required this.client,
  });
  final Client client;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(28.0),
          child: Center(
            child: Text(
              "Welcome in MinesTRIX",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Text(
            "Onboarding",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        WelcomeActionsButton(
            icon: Icons.people,
            text: 'Create your page',
            subtitle: 'That\'s where you can post',
            onPressed: () async {
              if (client.userRoomCreated) {
                await context.navigateTo(
                    UserViewRoute(userID: Matrix.of(context).client.userID));
              } else {
                await client.createPrivateMinestrixProfile();
              }
            },
            done: client.userRoomCreated),
        if (client.userRoomCreated == true)
          WelcomeActionsButton(
              icon: Icons.post_add,
              text: 'Post',
              subtitle: "Write a post on your page",
              onPressed: () async {
                await PostEditorPage.show(
                    context: context, rooms: client.minestrixUserRoom);
              },
              done: false),
        WelcomeActionsButton(
            icon: Icons.public,
            text: 'Publish your page',
            subtitle:
                'To help your find your page you can add it to your user space',
            onPressed: () async {
              context.pushRoute(const AccountsDetailsRoute());
            },
            done: false),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Text(
            "Go further",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        WelcomeActionsButton(
            text: 'Story',
            subtitle: 'Create and manage your story page',
            icon: Icons.web_stories,
            onPressed: () async {
              context.pushRoute(const SettingsStorysRoute());
            },
            done: false),
        WelcomeActionsButton(
            icon: Icons.group_work,
            text: 'Create your group page',
            subtitle: 'A place to share posts',
            onPressed: () async {
              AdaptativeDialogs.show(
                  context: context,
                  builder: (context) => const CreateGroupPage());
            },
            done: false),
        WelcomeActionsButton(
            text: 'Explore',
            subtitle: 'Discover public pages',
            icon: Icons.explore,
            onPressed: () async {
              context.pushRoute(
                  SearchRoute(initialSearchMode: SearchMode.publicRoom));
            },
            done: false),
      ],
    );
  }
}

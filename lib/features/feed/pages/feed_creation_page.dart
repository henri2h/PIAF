import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:piaf/utils/minestrix/minestrix_client_extension.dart';

import '../../../partials/dialogs/adaptative_dialogs.dart';
import '../../../utils/matrix_widget.dart';
import '../../groups/pages/create_group_page.dart';

@RoutePage()
class FeedCreationPage extends StatelessWidget {
  const FeedCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Scaffold(
        appBar: AppBar(title: const Text("Create a new feed")),
        body: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text("Create a new personal feed"),
                subtitle: const Text(
                    "Create your private personal feed. Only you and your friends will be able to see your posts."),
                leading: const CircleAvatar(child: Icon(Icons.feed)),
                trailing: const Icon(Icons.add),
                onTap: () async {
                  await client.createPrivateMinestrixProfile();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Create a new public feed"),
                subtitle: const Text(
                    "Create your public personal feed. Everyone will be able to see your posts."),
                leading: const CircleAvatar(child: Icon(Icons.public)),
                trailing: const Icon(Icons.add),
                onTap: () async {
                  await client.createPublicMinestrixProfile();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Create a new group"),
                subtitle: const Text("A group to share posts"),
                leading: const CircleAvatar(child: Icon(Icons.group_add)),
                trailing: const Icon(Icons.add),
                onTap: () async {
                  await AdaptativeDialogs.show(
                      context: context,
                      builder: (context) => const CreateGroupPage());
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ));
  }
}

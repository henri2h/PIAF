import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/minestrix/minestrix_friends_suggestions.dart';
import 'package:piaf/partials/utils/matrix_widget.dart';

import '../partials/components/account/account_card.dart';
import '../partials/components/layouts/custom_header.dart';

@RoutePage()
class FollowRecommendationsPage extends StatefulWidget {
  const FollowRecommendationsPage({super.key});

  @override
  State<FollowRecommendationsPage> createState() =>
      _FollowRecommendationsPageState();
}

class _FollowRecommendationsPageState extends State<FollowRecommendationsPage> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Follow recommendations"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Suggestions"),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              child: const Icon(Icons.info),
            ),
            subtitle: const Text(
                "Follow suggestions based on your friends followers."),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: FutureBuilder<List<Profile>>(
                future: client.getFriendsSuggestions(),
                builder: (context, snap) {
                  if (snap.hasData == false) return const Text("Loading");
                  return GridView.extent(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.7,
                    children: [
                      for (Profile p in snap.data!)
                        AccountCard(
                          profile: p,
                          displaySend: true,
                        ),
                    ],
                  );
                }),
          ),
        ],
      ),
    );
  }
}

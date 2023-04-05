import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_friends_suggestions.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../../partials/components/account/account_card.dart';
import '../../partials/components/layouts/custom_header.dart';

@RoutePage()
class FollowRecommendationsPage extends StatefulWidget {
  const FollowRecommendationsPage({Key? key}) : super(key: key);

  @override
  State<FollowRecommendationsPage> createState() =>
      _FollowRecommendationsPageState();
}

class _FollowRecommendationsPageState extends State<FollowRecommendationsPage> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Column(
      children: [
        const CustomHeader(title: "Follow recommendations"),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: FutureBuilder<List<Profile>>(
                future: client.getFriendsSuggestions(),
                builder: (context, snap) {
                  if (snap.hasData == false) return const Text("Loading");
                  return GridView.extent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.7,
                    children: [
                      for (Profile p in snap.data!) AccountCard(profile: p, displaySend: true,),
                    ],
                  );
                }),
          ),
        ),
      ],
    );
  }
}

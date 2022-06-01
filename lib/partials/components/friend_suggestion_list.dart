import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrix_friends_suggestions.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import 'account/account_card.dart';

class FriendSuggestionsList extends StatefulWidget {
  const FriendSuggestionsList({Key? key}) : super(key: key);

  @override
  State<FriendSuggestionsList> createState() => _FriendSuggestionsListState();
}

class _FriendSuggestionsListState extends State<FriendSuggestionsList> {
  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: FutureBuilder<List<Profile>>(
            future: client.getFriendsSuggestions(),
            builder: (context, snap) {
              if (snap.hasData == false) return Text("Loading");
              return Row(
                children: [
                  for (Profile p in snap.data!) AccountCard(profile: p),
                ],
              );
            }),
      ),
    );
  }
}

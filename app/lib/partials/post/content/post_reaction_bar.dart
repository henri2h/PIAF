import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/matrix/reactions_list.dart';

import 'post_reactions.dart';
import '../post_item.dart';
import 'post_button.dart';

class ReactionBar extends StatelessWidget {
  const ReactionBar({
    Key? key,
    required this.controller,
    required this.reactions,
    required this.isMobile,
  }) : super(key: key);

  final PostItemState controller;
  final Set<Event>? reactions;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (reactions?.isNotEmpty ?? false)
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: MaterialButton(
                                child: PostReactions(
                                    event: controller.post,
                                    reactions: reactions!),
                                onPressed: () async {
                                  await AdaptativeDialogs.show(
                                      context: context,
                                      builder: (context) => EventReactionList(
                                          reactions: reactions!),
                                      title: "Reactions");
                                }),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            child: PostButton(
              iconOnly: isMobile,
              text: "React",
              icon: Icons.insert_emoticon_outlined,
              onPressed: () {},
            ),
            onTapDown: (TapDownDetails detail) async {
              controller.onReact(detail.globalPosition);
            },
          ),
          const SizedBox(width: 9),
          if (controller.canComment)
            PostButton(
              iconOnly: isMobile,
              text: "Comment",
              icon: Icons.comment_outlined,
              onPressed: controller.replyButtonClick,
            ),
          if (controller.canShare)
            Padding(
              padding: const EdgeInsets.only(left: 9.0),
              child: MaterialButton(
                elevation: 0,
                color: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                onPressed: controller.share,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share,
                        color: Theme.of(context).colorScheme.onPrimary),
                    const SizedBox(width: 5),
                    Text("Share",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary))
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

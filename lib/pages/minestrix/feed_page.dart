import 'package:flutter/material.dart';
import 'package:minestrix/partials/feed/minestrix_feed.dart';
import 'package:minestrix/partials/navigation/rightbar.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  FeedPageState createState() => FeedPageState();
}

class FeedPageState extends State<FeedPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final feedOnly = constraints.maxWidth < 860;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 12,
              child: !feedOnly
                  ? Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: const MinestrixFeed()),
                    )
                  : const MinestrixFeed(),
            ),
            if (!feedOnly)
              Flexible(
                flex: 6,
                fit: FlexFit.loose,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: const RightBar()),
              ),
          ],
        );
      },
    );
  }
}

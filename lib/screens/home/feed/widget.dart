import 'package:flutter/material.dart';
import 'package:minestrix/components/postView.dart';

class FeedView extends StatefulWidget {
  @override
  _FeedViewState createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(children: <Widget>[
      Post(),
      Post(),
      Post(),
      Post(),
      Post(),
      Post(),
      Post(),
      Post(),
      Post(),
    ]));
  }
}

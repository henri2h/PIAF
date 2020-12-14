import 'package:flutter/material.dart';

class Post extends StatefulWidget {
  @override
  _PostState createState() => _PostState();
}

class _PostState extends State<Post> with SingleTickerProviderStateMixin {
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(5),
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PostHeader(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PostContent(),
                ),
                PostFooter()
              ],
            )),
      ),
    );
  }
}

class PostFooter extends StatelessWidget {
  const PostFooter({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      
      FlatButton(child: Text("React"), onPressed: () {})
    ]);
  }
}

class PostHeader extends StatelessWidget {
  const PostHeader({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: <Widget>[
            Text("Henri",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(" to ", style: TextStyle(fontSize: 20)),
            Text("Beta Tester 0",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ),
        Row(
          children: [
            Text("5 minutes ago",
            style: TextStyle(fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.enhanced_encryption),
            ),
          ],
        )
      ],
    );
  }
}

class PostContent extends StatelessWidget {
  const PostContent({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("Lorem ipsum"),
            Text("hello"),
            Text("What are you gonna do ..."),
          ]),
    );
  }
}

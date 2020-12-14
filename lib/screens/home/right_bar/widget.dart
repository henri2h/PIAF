import 'package:flutter/material.dart';

class RightBar extends StatefulWidget {
  @override
  _RightBarState createState() => _RightBarState();
}

class _RightBarState extends State<RightBar>
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
    return ListView(children: [ContactView(), ContactView()]);
  }
}

class ContactView extends StatelessWidget {
  const ContactView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        child: Card(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.account_box),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text("name",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text("matrixid")
                                ]),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text("name",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text("matrixid")
                            ]),
                      ),
                      Icon(Icons.verified_user),
                    ]))));
  }
}

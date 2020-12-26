import 'package:flutter/material.dart';
import 'package:minestrix/components/pageTitle.dart';
import 'package:minestrix/components/postView.dart';
import 'package:minestrix/global/smatrix.dart';
import 'package:minestrix/global/smatrixWidget.dart';

class UserFeedView extends StatelessWidget {
  const UserFeedView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    return Column(
      children: [
        PageTitle("User feed"),
        UserInfo(),
        Flexible(
          child: StreamBuilder(
            stream: sclient.onTimelineUpdate.stream,
            builder: (context, _) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sclient.stimeline.length,
                itemBuilder: (BuildContext context, int i) =>
                    Post(event: sclient.stimeline[i])),
          ),
        ),
      ],
    );
  }
}

class UserInfo extends StatelessWidget {
  const UserInfo({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("User name"),
        Text("user id"),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:minestrix/components/pageTitle.dart';
import 'package:minestrix/components/postView.dart';
import 'package:minestrix/global/smatrix.dart';

class FeedView extends StatelessWidget {
  const FeedView({
    Key key,
    @required this.sclient,
  }) : super(key: key);

  final SClient sclient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle("Feed"),
        Flexible(
          child: StreamBuilder(
            stream: sclient.onTimelineUpdate.stream,
            builder: (context, _) => ListView.builder(
                itemCount: sclient.stimeline.length,
                itemBuilder: (BuildContext context, int i) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                          color: Colors.white,
                          elevation: 3,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Post(event: sclient.stimeline[i]),
                          )),
                    )),
          ),
        ),
      ],
    );
  }
}

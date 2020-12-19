import 'package:cached_network_image/cached_network_image.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MImage extends StatelessWidget {
  const MImage({Key key, @required this.event}) : super(key: key);
  final Event event;
  @override
  Widget build(BuildContext context) {
    String url = event.getAttachmentUrl();
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: url,
        ),
      ],
    );
  }
}

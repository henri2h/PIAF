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
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CachedNetworkImage(
          imageUrl: url,
          progressIndicatorBuilder: (context, url, downloadProgress) =>
              CircularProgressIndicator(value: downloadProgress.progress),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }
}

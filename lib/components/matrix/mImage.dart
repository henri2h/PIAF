import 'package:cached_network_image/cached_network_image.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MImage extends StatelessWidget {
  const MImage({Key key, @required this.event}) : super(key: key);
  final Event event;

  Widget getImage(url) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: url != null
              ? CachedNetworkImage(
                  imageUrl: url,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      CircularProgressIndicator(
                          value: downloadProgress.progress),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                )
              : Icon(Icons.error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String url = event.getAttachmentUrl();

    if (event.isAttachmentEncrypted) {
      return FutureBuilder<MatrixFile>(
        future: event.downloadAndDecryptAttachment(),
        builder: (BuildContext context, AsyncSnapshot<MatrixFile> file) {
          if (file.hasData) {
            print(file.data.mimeType);
            return ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.memory(file.data.bytes));
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }
    return getImage(url);
  }
}

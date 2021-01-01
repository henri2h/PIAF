import 'package:cached_network_image/cached_network_image.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class MatrixUserImage extends StatelessWidget {
  MatrixUserImage({Key key, @required this.url})
      : super(key: key);
  final Uri url;
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    if (url == null) return Icon(Icons.image);
    return CachedNetworkImage(
      imageUrl: url.getThumbnail(
        sclient,
        width: 30,
        height: 30,
      ),
      imageBuilder: (context, imageProvider) => Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          CircularProgressIndicator(value: downloadProgress.progress),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }
}

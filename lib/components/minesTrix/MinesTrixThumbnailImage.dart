import 'package:cached_network_image/cached_network_image.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class MinesTrixThumbnailImage extends StatelessWidget {
  MinesTrixThumbnailImage(
      {Key key,
      @required this.url,
      this.width,
      this.height,
      this.isCircle = true})
      : super(key: key);
  final Uri url;
  final double width;
  final double height;
  final bool isCircle;
  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    double h = height != null ? height : 30;
    double w = width != null ? width : 30;
    if (url == null)
      return Container(
          height: h,
          width: w,
          decoration: isCircle
              ? BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                )
              : null,
          child: Icon(Icons.image));
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: CachedNetworkImage(
        height: h,
        width: w,
        imageUrl: url.getThumbnail(
          sclient,
          height: h,
          width: w,
        ),
        progressIndicatorBuilder: (context, url, downloadProgress) =>
            CircularProgressIndicator(value: downloadProgress.progress),
        errorWidget: (context, url, error) => Icon(Icons.error),
      ),
    );
  }
}

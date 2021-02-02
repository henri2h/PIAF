import 'package:cached_network_image/cached_network_image.dart';
import 'package:famedlysdk/famedlysdk.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/global/smatrixWidget.dart';
import 'package:minestrix/global/smatrix.dart';

class MinesTrixUserImage extends StatelessWidget {
  MinesTrixUserImage(
      {Key key,
      @required this.url,
      this.width,
      this.height,
      this.maxWidth,
      this.maxHeight,
      this.rounded = true,
      this.thumnail = false,
      this.fit = false,
      this.defaultIcon = const Icon(Icons.image),
      this.unconstraigned = false})
      : super(key: key);
  final Uri url;
  final double width;
  final double height;
  final bool rounded;
  final bool thumnail;
  final bool unconstraigned;
  final bool fit;
  final Icon defaultIcon;
  final int maxWidth;
  final int maxHeight;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;
    double h = height != null ? height : 30;
    double w = width != null ? width : 30;
    if (url == null)
      return Container(
          height: h,
          width: w,
          decoration: rounded
              ? BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                )
              : null,
          child: defaultIcon);
    return ClipRRect(
      borderRadius: rounded ? BorderRadius.circular(10.0) : BorderRadius.zero,
      child: CachedNetworkImage(
        fit: fit ? BoxFit.cover : BoxFit.contain,
        height: unconstraigned ? null : h,
        width: unconstraigned ? null : w,
        maxHeightDiskCache: maxHeight,
        maxWidthDiskCache: maxWidth,
        imageUrl: thumnail
            ? url.getThumbnail(
                sclient,
                height: h,
                width: w,
              )
            : url.getDownloadLink(sclient),
        progressIndicatorBuilder: (context, url, downloadProgress) =>
            CircularProgressIndicator(value: downloadProgress.progress),
        errorWidget: (context, url, error) => Icon(Icons.error),
      ),
    );
  }
}

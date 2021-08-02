import 'package:cached_network_image/cached_network_image.dart';
import 'package:matrix/matrix.dart';
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
      this.backgroundColor,
      this.rounded = true,
      this.thumnail = false,
      this.fit = false,
      this.defaultIcon = const Icon(Icons.image, color: Colors.black),
      this.unconstraigned = false})
      : super(key: key);
  final Uri url;
  final double width;
  final double height;
  final bool rounded;
  final bool thumnail;
  final bool unconstraigned;
  final bool fit;
  final Widget defaultIcon;
  final int maxWidth;
  final int maxHeight;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    SClient sclient = Matrix.of(context).sclient;

    double h = height != null ? height : 30;
    double w = width != null ? width : 30;

    if (url == null)
      return ClipRRect(
          borderRadius:
              rounded ? BorderRadius.circular(10.0) : BorderRadius.zero,
          /*decoration: rounded
              ? BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                )
              : null,*/
          child: Container(
              color: backgroundColor,
              child: SizedBox(
                  height: unconstraigned ? null : h,
                  width: unconstraigned ? null : w,
                  child: Center(child: defaultIcon))));

    String httpurl = thumnail
        ? url
            .getThumbnail(
              sclient,
              height: h,
              width: w,
            )
            .toString()
        : url.getDownloadLink(sclient).toString();
    return ClipRRect(
      borderRadius: rounded ? BorderRadius.circular(10.0) : BorderRadius.zero,
      child: CachedNetworkImage(
        fit: fit ? BoxFit.cover : BoxFit.contain,
        height: unconstraigned ? null : h,
        width: unconstraigned ? null : w,
        maxHeightDiskCache: maxHeight,
        maxWidthDiskCache: maxWidth,
        imageUrl: httpurl,
        progressIndicatorBuilder: (context, url, downloadProgress) =>
            CircularProgressIndicator(value: downloadProgress.progress),
        /*IconButton(
                    icon: Icon(Icons.error),
                    onPressed: () async {
                      print("evict from cache");
                      await CachedNetworkImage.evictFromCache(url);
                      print("done");
                    })*/

        errorWidget: (context, url, error) => Icon(Icons.error),
      ),
    );
  }
}

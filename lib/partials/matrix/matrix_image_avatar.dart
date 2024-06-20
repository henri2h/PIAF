import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:matrix/matrix.dart';

import 'package:piaf/helpers/text_helper.dart';

enum MatrixImageAvatarShape { circle, rounded, none }

class MinestrixAvatarSizeConstants {
  static const double big = 180;
  static const double large = 80;
  static const double medium = 60;
  static const double small = 40;
  static const double extraSmall = 34;
  static const double avatar = 46;
}

class MatrixImageAvatar extends StatelessWidget {
  const MatrixImageAvatar(
      {super.key,
      required this.url,
      this.width,
      this.height,
      this.maxWidth,
      this.maxHeight,
      this.backgroundColor,
      this.shape = MatrixImageAvatarShape.circle,
      this.borderRadius,
      this.thumnailOnly = true,
      this.fit = false,
      this.defaultIcon = const Icon(Icons.image),
      this.defaultText,
      this.unconstraigned = false,
      this.displayProgress = false,
      this.textPadding = 5,
      required this.client})
      : assert(
            !(borderRadius != null && shape == MatrixImageAvatarShape.rounded));
  final Uri? url;
  final double? width;
  final double? height;
  final MatrixImageAvatarShape shape;
  final BorderRadius? borderRadius;
  final bool thumnailOnly;
  final bool unconstraigned;
  final bool fit;
  final Widget defaultIcon;
  final String? defaultText;
  final double textPadding;
  final int? maxWidth;
  final int? maxHeight;
  final Color? backgroundColor;
  final bool displayProgress;
  final Client? client;

  @override
  Widget build(BuildContext context) {
    double h = height ?? MinestrixAvatarSizeConstants.small;
    double w = width ?? MinestrixAvatarSizeConstants.small;

    double roomInitialsTextPadding = h <= 40 ? textPadding : 9; // hmm dirty fix

    final thumnailUrl = url
        ?.getThumbnail(
          client!,
          height: h,
          width: w,
        )
        .toString();
    final httpurl =
        thumnailOnly ? null : url?.getDownloadLink(client!).toString();

    final placeholder = Padding(
        padding: EdgeInsets.all(roomInitialsTextPadding),
        child: Center(
            child: defaultText != null
                ? AutoSizeText(TextHelper.getRoomInitial(defaultText!),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 40,
                        color: Theme.of(context).colorScheme.onPrimary))
                : defaultIcon));

    final circlePlaceholder = Container(
      decoration: BoxDecoration(
        shape: shape == MatrixImageAvatarShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: borderRadius ??
            (shape == MatrixImageAvatarShape.rounded
                ? BorderRadius.circular(6.0)
                : shape == MatrixImageAvatarShape.circle
                    ? null
                    : BorderRadius.zero),
        color: backgroundColor ?? Theme.of(context).colorScheme.primary,
      ),
      height: unconstraigned ? null : h,
      width: unconstraigned ? null : w,
      child: placeholder,
    );

    return Container(
      child: url == null || (httpurl ?? thumnailUrl) == null
          ? circlePlaceholder
          : SizedBox(
              height: unconstraigned ? null : h,
              width: unconstraigned ? null : w,
              child: CachedNetworkImage(
                // fit: fit ? BoxFit.cover : BoxFit.contain,
                //height: unconstraigned ? null : h,
                //width: unconstraigned ? null : w,
                maxHeightDiskCache: maxHeight,
                maxWidthDiskCache: maxWidth,

                imageUrl: httpurl ?? thumnailUrl!,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    shape: shape == MatrixImageAvatarShape.circle
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: borderRadius ??
                        (shape == MatrixImageAvatarShape.rounded
                            ? BorderRadius.circular(10.0)
                            : shape == MatrixImageAvatarShape.circle
                                ? null
                                : BorderRadius.zero),
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover),
                  ),
                  height: unconstraigned ? null : h,
                  width: unconstraigned ? null : w,
                ),
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    httpurl != null
                        ? CachedNetworkImage(
                            // fit: fit ? BoxFit.cover : BoxFit.contain,
                            //height: unconstraigned ? null : h,
                            //width: unconstraigned ? null : w,
                            maxHeightDiskCache: maxHeight,
                            maxWidthDiskCache: maxWidth,

                            imageUrl: thumnailUrl!,
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                shape: shape == MatrixImageAvatarShape.circle
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: borderRadius ??
                                    (shape == MatrixImageAvatarShape.rounded
                                        ? BorderRadius.circular(10.0)
                                        : shape == MatrixImageAvatarShape.circle
                                            ? null
                                            : BorderRadius.zero),
                                image: DecorationImage(
                                    image: imageProvider, fit: BoxFit.cover),
                              ),
                              height: unconstraigned ? null : h,
                              width: unconstraigned ? null : w,
                            ),
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) =>
                                    displayProgress
                                        ? CircularProgressIndicator(
                                            value: downloadProgress.progress)
                                        : placeholder,
                            errorWidget: (context, url, error) => placeholder,
                          )
                        : displayProgress
                            ? CircularProgressIndicator(
                                value: downloadProgress.progress)
                            : circlePlaceholder,
                errorWidget: (context, url, error) => circlePlaceholder,
              ),
            ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/utils/platforms_info.dart';

class AdaptiveFlatButton extends StatelessWidget {
  final Widget child;
  final Color textColor;
  final Function onPressed;

  const AdaptiveFlatButton({
    Key key,
    this.child,
    this.textColor,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformInfos.isCupertinoStyle) {
      return CupertinoDialogAction(
        child: child,
        onPressed: onPressed,
        textStyle: textColor != null ? TextStyle(color: textColor) : null,
      );
    }
    return FlatButton(
      child: child,
      textColor: textColor,
      onPressed: onPressed,
    );
  }
}

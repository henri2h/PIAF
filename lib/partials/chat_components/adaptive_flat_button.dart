import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/platform_infos.dart';

class AdaptiveFlatButton extends StatelessWidget {
  final String label;
  final Color? textColor;
  final void Function()? onPressed;

  const AdaptiveFlatButton({
    super.key,
    required this.label,
    this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfos.isCupertinoStyle) {
      return CupertinoDialogAction(
        onPressed: onPressed,
        textStyle: textColor != null ? TextStyle(color: textColor) : null,
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(color: textColor),
      ),
    );
  }
}

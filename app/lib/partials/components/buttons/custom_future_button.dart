import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomFutureButton extends StatefulWidget {
  final AsyncCallback? onPressed;
  final Widget? icon;
  final List<Widget> children;
  final Color? color;
  final bool expanded;
  final EdgeInsets? padding;

  const CustomFutureButton(
      {Key? key,
      required this.onPressed,
      required this.children,
      this.icon,
      this.expanded = true,
      this.padding,
      this.color})
      : super(key: key);

  @override
  CustomFutureButtonState createState() => CustomFutureButtonState();
}

class CustomFutureButtonState extends State<CustomFutureButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MaterialButton(
          minWidth: 0,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: widget.color,
          onPressed: widget.onPressed != null
              ? () async {
                  if (loading) return;

                  setState(() {
                    loading = true;
                  });
                  try {
                    if (widget.onPressed != null) await widget.onPressed!();
                  } finally {
                    if (mounted) {
                      setState(() {
                        loading = false;
                      });
                    }
                  }
                }
              : null,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading || widget.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : widget.icon,
                  ),
                widget.expanded
                    ? Expanded(
                        child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [...widget.children],
                        ),
                      ))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [...widget.children],
                        ),
                      )
              ],
            ),
          )),
    );
  }
}

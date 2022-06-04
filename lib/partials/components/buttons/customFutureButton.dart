import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomFutureButton extends StatefulWidget {
  final AsyncCallback? onPressed;
  final Widget icon;
  final List<Widget> children;
  final Color? color;
  final bool expanded;
  final EdgeInsets? padding;

  const CustomFutureButton(
      {Key? key,
      required this.onPressed,
      required this.children,
      required this.icon,
      this.expanded = true,
      this.padding,
      this.color})
      : super(key: key);

  @override
  _CustomFutureButtonState createState() => _CustomFutureButtonState();
}

class _CustomFutureButtonState extends State<CustomFutureButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
        minWidth: 0,
        padding: EdgeInsets.zero,
        child: Card(
          color: widget.color,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : widget.icon,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: widget.expanded
                      ? Expanded(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [...widget.children],
                        ))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [...widget.children],
                        ),
                )
              ],
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        onPressed: widget.onPressed != null
            ? () async {
                if (loading) return;

                setState(() {
                  loading = true;
                });
                try {
                  if (widget.onPressed != null) await widget.onPressed!();
                } finally {
                  if (mounted)
                    setState(() {
                      loading = false;
                    });
                }
              }
            : null);
  }
}

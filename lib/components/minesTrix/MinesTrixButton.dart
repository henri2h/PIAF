import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTheme.dart';

class MinesTrixButton extends StatefulWidget {
  MinesTrixButton(
      {Key? key,
      this.onPressed,
      this.onFuturePressed,
      required this.label,
      required this.icon})
      : super(key: key);
  final VoidCallback? onPressed;
  final AsyncCallback? onFuturePressed;
  final IconData icon;
  final String label;
  @override
  _MinesTrixButtonState createState() => _MinesTrixButtonState();
}

class _MinesTrixButtonState extends State<MinesTrixButton> {
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(80.0)),
            padding: const EdgeInsets.all(0.0)),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: MinesTrixTheme.buttonGradient,
            borderRadius: BorderRadius.all(Radius.circular(80.0)),
          ),
          child: Container(
            constraints: const BoxConstraints(
                minWidth: 88.0,
                minHeight: 36.0), // min sizes for Material buttons
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  !loading
                      ? Icon(widget.icon, color: Colors.white)
                      : CircularProgressIndicator(
                          color: Colors.white,
                        ),
                  SizedBox(width: 10),
                  Flexible(
                      child: Text(widget.label,
                          style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          ),
        ),
        onPressed: (widget.onPressed ?? widget.onFuturePressed) != null
            ? () async {
                if (loading == false) {
                  setState(() {
                    loading = true;
                  });
                  print("oups");
                  widget.onPressed?.call();
                  if (widget.onFuturePressed != null) {
                    await widget.onFuturePressed!();
                  }
                  print("done");
                  setState(() {
                    loading = false;
                  });
                }
              }
            : null);
  }
}

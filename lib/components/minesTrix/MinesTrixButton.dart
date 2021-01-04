import 'package:flutter/material.dart';
import 'package:minestrix/components/minesTrix/MinesTrixTheme.dart';

class MinesTrixButton extends StatelessWidget {
  MinesTrixButton(
      {Key key,
      @required this.onPressed,
      @required this.label,
      @required this.icon})
      : super(key: key);
  final Function onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(80.0)),
        padding: const EdgeInsets.all(0.0),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: MinesTrixTheme.buttonGradient,
            borderRadius: BorderRadius.all(Radius.circular(80.0)),
          ),
          child: Container(
            constraints: const BoxConstraints(
                minWidth: 88.0,
                minHeight: 36.0), // min sizes for Material buttons
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,color: Colors.white),
                SizedBox(width: 10),
                Text(label, style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        onPressed: onPressed);
  }
}

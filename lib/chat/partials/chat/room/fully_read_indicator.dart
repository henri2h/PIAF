import 'package:flutter/material.dart';

class FullyReadIndicator extends StatelessWidget {
  const FullyReadIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8.0, top: 14),
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                  child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              )),
              Text("Fully read"),
              Expanded(
                  child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(),
              ))
            ],
          ),
        ),
      ),
    );
  }
}

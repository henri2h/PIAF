import 'package:flutter/material.dart';

import 'package:auto_route/src/router/auto_router_x.dart';

import 'package:minestrix/partials/components/minesTrix/MinesTrixTitle.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader(this.title, {Key? key, this.actionButton, this.onBack})
      : super(key: key);

  final String title;
  final List<Widget>? actionButton;
  final Future<void> Function()? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (context.router.canPopSelfOrChildren)
                  IconButton(
                      onPressed: () {
                        if (onBack != null) onBack!();
                        context.router.pop();
                      },
                      icon: Icon(Icons.arrow_back)),
                if (context.router.canPopSelfOrChildren == false)
                  IconButton(
                      onPressed: () {
                        if (onBack != null) onBack!();
                        Scaffold.of(context).openDrawer();
                      },
                      icon: Icon(Icons.menu)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: H1Title(
                      title,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actionButton != null)
            Row(
              children: [for (Widget a in actionButton!) a],
            )
        ],
      ),
    );
  }
}

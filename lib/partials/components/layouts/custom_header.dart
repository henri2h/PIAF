import 'package:auto_route/src/router/auto_router_x.dart';
import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader(
      {Key? key,
      this.actionButton,
      this.onBack,
      this.drawerEnabled = false,
      this.overrideCanPop = false,
      this.child,
      this.title})
      : super(key: key);

  final String? title;
  final Widget? child;
  final List<Widget>? actionButton;
  final Future<void> Function()? onBack;
  final bool overrideCanPop;
  final bool drawerEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (context.router.canPopSelfOrChildren || overrideCanPop)
                    IconButton(
                        onPressed: () {
                          if (onBack != null) onBack!();
                          context.router.pop();
                        },
                        icon: const Icon(Icons.arrow_back)),
                  if (context.router.canPopSelfOrChildren == false &&
                      drawerEnabled)
                    IconButton(
                        onPressed: () {
                          if (onBack != null) onBack!();
                          Scaffold.of(context).openDrawer();
                        },
                        icon: const Icon(Icons.menu)),
                  if (child != null) Flexible(child: child!),
                  if (title != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(title!,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}

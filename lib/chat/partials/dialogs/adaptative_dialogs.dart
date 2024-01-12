import 'package:flutter/material.dart';
import '../../style/constants.dart';

/// Special class to generate modals adapated to the screen size.
class AdaptativeDialogs {
  static Future<T?> show<T>(
      {required BuildContext context,
      required Widget Function(BuildContext) builder,
      Widget? subtitle,
      List<Widget>? actions,
      bool bottomSheet = true,
      String? title,
      bool useSafeArea = true}) async {
    if (bottomSheet &&
        [TargetPlatform.iOS].contains(Theme.of(context).platform)) {
      return await showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          children: [
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                SizedBox(
                  width: 60,
                  child: TextButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      }),
                ),
                Expanded(
                    child: Text(title ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary))),
                const SizedBox(
                  width: 60,
                )
              ]),
            ),
            if (subtitle != null)
              Container(color: Theme.of(context).cardColor, child: subtitle),
            Expanded(child: builder(context)),
          ],
        ),
      );
    } else if (bottomSheet &&
        [TargetPlatform.android].contains(Theme.of(context).platform)) {
      return await showModalBottomSheet(
        context: context,
        useSafeArea: useSafeArea,
        isScrollControlled: true,
        builder: (context) => Column(
          children: [
            if (title != null || actions != null)
              AppBar(
                title: Text(title ?? ''),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: actions,
              ),
            if (subtitle != null) subtitle,
            Expanded(child: builder(context)),
          ],
        ),
      );
    }

    return await showDialog<T>(
        context: context,
        builder: (context) => LayoutBuilder(builder: (context, constraints) {
              final navigator = AdaptativeDialogsWidget(
                  enableClose: true,
                  title: title,
                  subtitle: subtitle,
                  child: Navigator(
                      pages: [MaterialPage(name: "/", child: builder(context))],
                      onPopPage: (route, result) {
                        Navigator.of(context).pop(result);
                        return false;
                      }));

              if (constraints.maxWidth < 600) {
                return Dialog(
                  shape: const ContinuousRectangleBorder(),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  insetPadding: EdgeInsets.zero,
                  child: navigator,
                );
              }

              return Dialog(child: navigator);
            }));
  }
}

class AdaptativeDialogsWidget extends StatelessWidget {
  const AdaptativeDialogsWidget(
      {super.key,
      required this.title,
      required this.child,
      this.subtitle,
      this.enableClose = false,
      this.onPressed,
      this.maxHeight = 800,
      this.maxWidth = 800});
  final String? title;
  final Widget child;
  final bool enableClose;
  final double maxWidth;
  final double maxHeight;
  final Widget? subtitle;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    if (enableClose)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              if (onPressed != null) {
                                onPressed!();
                              } else {
                                Navigator.of(context).pop();
                              }
                            }),
                      ),
                    Expanded(
                        child: Text(title!, style: Constants.kTextTitleStyle)),
                  ],
                ),
              ),
            ),
          if (subtitle != null) subtitle!,
          Expanded(
            child: child,
          )
        ],
      ),
    );
  }
}

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class PopupRouteWrapper extends PopupRoute {
  PopupRouteWrapper(
      {required this.anchorKeyContext,
      required this.builder,
      this.offset,
      this.maxHeight = 500,
      this.useAnimation = true});

  final Widget Function(Rect) builder;

  final BuildContext? anchorKeyContext;
  final Offset? offset;
  final bool useAnimation;
  final double maxHeight;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  late final SearchViewThemeData viewTheme;
  late final DividerThemeData dividerTheme;
  final RectTween _rectTween = RectTween();

  Rect? getRect() {
    final BuildContext? context = anchorKeyContext;

    if (offset != null) {
      return offset! & const Size(400, 200);
    }

    if (context != null) {
      final RenderBox searchBarBox = context.findRenderObject()! as RenderBox;
      const Size boxSize = Size(400,
          200); // Fixed initial minimum size to prevent overflow at the minimum size
      final NavigatorState navigator = Navigator.of(context);

      final Offset boxLocation = searchBarBox.localToGlobal(
          Offset(0, searchBarBox.size.height),
          ancestor: navigator.context.findRenderObject());
      return boxLocation & boxSize;
    }
    return null;
  }

  @override
  TickerFuture didPush() {
    assert(anchorKeyContext != null);
    updateViewConfig(anchorKeyContext!);
    return super.didPush();
  }

  void updateViewConfig(BuildContext context) {
    viewTheme = SearchViewTheme.of(context);
    dividerTheme = DividerTheme.of(context);
  }

  void updateTweens(BoxConstraints constraints) {
    final Size screenSize = Size(constraints.maxWidth, constraints.maxHeight);

    final Rect anchorRect = getRect() ?? Rect.zero;
    BoxConstraints effectiveConstraints =
        BoxConstraints(minWidth: 200.0, minHeight: 120.0, maxHeight: maxHeight);
    _rectTween.begin = anchorRect;

    final double viewWidth = clampDouble(anchorRect.width,
        effectiveConstraints.minWidth, effectiveConstraints.maxWidth);
    final double viewHeight = clampDouble(screenSize.height * 2 / 3,
        effectiveConstraints.minHeight, effectiveConstraints.maxHeight);

    final double viewLeftToScreenRight = screenSize.width - anchorRect.left;
    final double viewTopToScreenBottom = screenSize.height - anchorRect.top;

    // Make sure the search view doesn't go off the screen. If the search view
    // doesn't fit, move the top-left corner of the view to fit the window.
    // If the window is smaller than the view, then we resize the view to fit the window.
    Offset topLeft = anchorRect.topLeft;
    if (viewLeftToScreenRight < viewWidth) {
      topLeft = Offset(
          screenSize.width - min(viewWidth, screenSize.width), topLeft.dy);
    }
    if (viewTopToScreenBottom < viewHeight) {
      topLeft = Offset(
          topLeft.dx, screenSize.height - min(viewHeight, screenSize.height));
    }
    final Size endSize = Size(viewWidth, viewHeight);
    _rectTween.end = (topLeft & endSize);
    return;
  }

  bool initialized = false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return LayoutBuilder(builder: (context, constraints) {
      if (!initialized) {
        updateTweens(constraints);
        initialized = true;
      }

      if (!useAnimation) {
        return builder(_rectTween.end!);
      }

      return Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final Animation<double> curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubicEmphasized,
                reverseCurve: Curves.easeInOutCubicEmphasized.flipped,
              );

              final Rect viewRect = _rectTween.evaluate(curvedAnimation)!;
              return builder(viewRect);
            }),
      );
    });
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);
}

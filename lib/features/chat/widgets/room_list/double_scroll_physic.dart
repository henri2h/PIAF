import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Save the scrolling state
class ScrollState {
  bool get canGoToTheTop => _reachedTop;
  // By default, we should be able to scroll up to display the filter
  bool _reachedTop = true;
  bool _reachedTopCache = true;

  final double selectorHeight;
  ScrollState({required this.selectorHeight});

  // Copy the cached value
  void apply() {
    _reachedTop = _reachedTopCache;
  }

  void clear() {
    _reachedTop = false;
    _reachedTopCache = false;
  }

  void hitTopEdge() {
    _reachedTopCache = true;
  }
}

class DoubleScrollPhysic extends ScrollPhysics {
  /// Creates scroll physics that prevent the scroll offset from exceeding the
  /// bounds of the first content.
  /// Copied from bounced physic.
  /// When the user scrolls up, we block at minExtent - selectorHeight
  /// In order to scroll above, the user has to stop scrolling (touch pointerUp)
  /// and start scrolling again
  const DoubleScrollPhysic(this.state, {super.parent});

  @override
  DoubleScrollPhysic applyTo(ScrollPhysics? ancestor) {
    return DoubleScrollPhysic(state, parent: buildParent(ancestor));
  }

  final ScrollState state;

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    assert(() {
      if (value == position.pixels) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              '$runtimeType.applyBoundaryConditions() was called redundantly.'),
          ErrorDescription(
            'The proposed new position, $value, is exactly equal to the current position of the '
            'given ${position.runtimeType}, ${position.pixels}.\n'
            'The applyBoundaryConditions method should only be called when the value is '
            'going to actually change the pixels, otherwise it is redundant.',
          ),
          DiagnosticsProperty<ScrollPhysics>(
              'The physics object in question was', this,
              style: DiagnosticsTreeStyle.errorProperty),
          DiagnosticsProperty<ScrollMetrics>(
              'The position object in question was', position,
              style: DiagnosticsTreeStyle.errorProperty),
        ]);
      }
      return true;
    }());

    final minScrollExtent = state.canGoToTheTop
        ? position.minScrollExtent
        : position.minScrollExtent + state.selectorHeight;

    if (position.pixels > state.selectorHeight) {
      state.clear();
    }

    if (value < position.pixels && position.pixels <= minScrollExtent) {
      // Underscroll.

      return value - position.pixels;
    }
    if (position.maxScrollExtent <= position.pixels &&
        position.pixels < value) {
      // Overscroll.
      return value - position.pixels;
    }
    if (value < minScrollExtent && minScrollExtent < position.pixels) {
      // Hit top edge.
      state.hitTopEdge();
      return value - minScrollExtent;
    }
    if (position.pixels < position.maxScrollExtent &&
        position.maxScrollExtent < value) {
      // Hit bottom edge.
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position);

    if (position.outOfRange) {
      double? end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      }
      if (position.pixels < position.minScrollExtent) {
        end = position.minScrollExtent;
      }
      assert(end != null);
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end!,
        math.min(0.0, velocity),
        tolerance: tolerance,
      );
    }
    if (velocity.abs() < tolerance.velocity) {
      return null;
    }
    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }
}

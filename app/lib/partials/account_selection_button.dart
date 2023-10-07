import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../pages/login_page.dart';
import '../pages/minestrix/groups/create_group_page.dart';
import '../router.gr.dart';

class AccountSelectionButton extends StatefulWidget {
  const AccountSelectionButton({super.key});

  @override
  State<AccountSelectionButton> createState() => _AccountSelectionButtonState();
}

class _AccountSelectionButtonState extends State<AccountSelectionButton> {
  final GlobalKey anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final client = Matrix.of(context).client;
      return IconButton(
        key: anchorKey,
        onPressed: () {
          Navigator.of(context)
              .push(_AccountSelectionRoute(anchorKey: anchorKey));
        },
        icon: FutureBuilder<Profile>(
            future: client.fetchOwnProfile(),
            builder: (context, snap) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: MatrixImageAvatar(
                  url: snap.data?.avatarUrl,
                  client: client,
                  defaultText: snap.data?.displayName ?? client.userID!,
                ),
              );
            }),
      );
    });
  }
}

class _AccountSelectionRoute extends PopupRoute<_AccountSelectionRoute> {
  _AccountSelectionRoute({
    required this.anchorKey,
  });

  final GlobalKey anchorKey;

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
    final BuildContext? context = anchorKey.currentContext;
    if (context != null) {
      final RenderBox searchBarBox = context.findRenderObject()! as RenderBox;
      final Size boxSize = searchBarBox.size;
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
    assert(anchorKey.currentContext != null);
    updateViewConfig(anchorKey.currentContext!);
    updateTweens(anchorKey.currentContext!);
    return super.didPush();
  }

  @override
  bool didPop(_AccountSelectionRoute? result) {
    assert(anchorKey.currentContext != null);
    updateTweens(anchorKey.currentContext!);
    return super.didPop(result);
  }

  void updateViewConfig(BuildContext context) {
    viewTheme = SearchViewTheme.of(context);
    dividerTheme = DividerTheme.of(context);
  }

  void updateTweens(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final Rect anchorRect = getRect() ?? Rect.zero;
    const BoxConstraints effectiveConstraints =
        BoxConstraints(minWidth: 460.0, minHeight: 240.0, maxHeight: 550);
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
          screenSize.width - math.min(viewWidth, screenSize.width), topLeft.dy);
    }
    if (viewTopToScreenBottom < viewHeight) {
      topLeft = Offset(topLeft.dx,
          screenSize.height - math.min(viewHeight, screenSize.height));
    }
    final Size endSize = Size(viewWidth, viewHeight);
    _rectTween.end = (topLeft & endSize);
    return;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
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

            return _AccountSelectionRouteContent(
              rect: viewRect,
            );
          }),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);
}

class _AccountSelectionRouteContent extends StatefulWidget {
  const _AccountSelectionRouteContent({required this.rect});
  final Rect rect;
  @override
  State<_AccountSelectionRouteContent> createState() =>
      _AccountSelectionRouteContentState();
}

class _AccountSelectionRouteContentState
    extends State<_AccountSelectionRouteContent> {
  Future<void> launchCreateGroupModal(BuildContext context) async {
    AdaptativeDialogs.show(
        context: context, builder: (context) => const CreateGroupPage());
  }

  @override
  Widget build(BuildContext context) {
    final rect = widget.rect;

    final m = Matrix.of(context);

    return Align(
        alignment: Alignment.topLeft,
        child: Transform.translate(
            offset: rect.topLeft,
            child: SizedBox(
              width: rect.width,
              height: rect.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text("Choose an account"),
                        ),
                        ListTile(
                            onTap: () async {
                              await context.navigateTo(UserViewRoute(
                                  userID: Matrix.of(context).client.userID));
                            },
                            title: const Text("My account"),
                            leading: const Icon(Icons.person)),
                        ListTile(
                            onTap: () {
                              launchCreateGroupModal(context);
                            },
                            leading: const Icon(Icons.group_add),
                            title: const Text("Create group")),
                        ListTile(
                            onTap: () async {
                              await Matrix.of(context)
                                  .client
                                  .openStoryEditModalOrCreate(context);
                            },
                            leading: const Icon(Icons.camera),
                            title: const Text("Create story")),
                        Expanded(
                          child: Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListView(
                                children: [
                                  for (final c in m.widget.clients)
                                    ListTile(
                                        title: Text(c.clientName),
                                        leading: FutureBuilder<Profile>(
                                            future: c.fetchOwnProfile(),
                                            builder: (context, snap) {
                                              return MatrixImageAvatar(
                                                url: snap.data?.avatarUrl,
                                                client: c,
                                                defaultText:
                                                    snap.data?.displayName,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                              );
                                            }),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(c.userID ?? ''),
                                          ],
                                        ),
                                        onTap: () async {
                                          m.setActiveClient(c);
                                          Navigator.of(context).pop();
                                        }),
                                  ListTile(
                                      title: const Text("Add an account"),
                                      trailing: const Icon(Icons.add),
                                      onTap: () async {
                                        await AdaptativeDialogs.show(
                                            context: context,
                                            bottomSheet: true,
                                            builder: (context) =>
                                                const LoginPage(
                                                    popOnLogin: true,
                                                    title:
                                                        "Add a new account"));
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text("Settings"),
                            onTap: () async {
                              context.popRoute();
                              context.pushRoute(const SettingsRoute());
                            }),
                      ],
                    ),
                  ),
                ),
              ),
            )));
  }
}

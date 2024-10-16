import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../utils/matrix_widget.dart';
import '../../features/chat/widgets/room_chat_card.dart';

class LayoutView extends StatelessWidget {
  const LayoutView(
      {super.key,
      this.controller,
      this.customHeaderText,
      this.customHeaderActionsButtons,
      this.customHeaderChild,
      required this.mainBuilder,
      this.sidebarBuilder,
      this.leftBar,
      this.headerChildBuilder,
      this.maxSidebarWidth = 1000,
      this.maxChatWidth = 1400,
      this.sidebarWidth = 300,
      this.mainWidth = 600,
      this.headerHeight,
      this.displayChat = true,
      this.maxHeaderWidth = 1200,
      this.room,
      this.appBarTitle,
      this.rightBar})
      : assert(!(customHeaderText != null && appBarTitle != null));

  final Widget? leftBar;
  final Widget? rightBar;
  final Widget Function({required bool displayLeftBar})? sidebarBuilder;
  final Widget Function(
      {required bool displaySideBar, required bool displayLeftBar}) mainBuilder;
  final Widget Function({required bool displaySideBar})? headerChildBuilder;

  final Room? room;

  final double maxSidebarWidth;

  final bool displayChat;
  final double maxChatWidth;

  final double sidebarWidth;
  final double mainWidth;

  final Widget? customHeaderChild;
  final String? customHeaderText;
  final List<Widget>? customHeaderActionsButtons;

  final ScrollController? controller;

  final double? headerHeight;
  final double maxHeaderWidth;

  final Widget? appBarTitle;

  static Gradient noImageBoxDecoration(BuildContext context) => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Theme.of(context).colorScheme.primary,
          Colors.grey.shade800,
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !(customHeaderText == null &&
              customHeaderChild == null &&
              customHeaderActionsButtons == null)
          ? AppBar(
              title: Text(customHeaderText ?? ''),
              leading: customHeaderChild,
              actions: customHeaderActionsButtons)
          : null,
      body: LayoutBuilder(builder: (context, constraints) {
        final displaySideBar =
            constraints.maxWidth >= maxSidebarWidth && sidebarBuilder != null;
        final displayChat = constraints.maxWidth >= maxChatWidth &&
            this.displayChat &&
            room != null;

        final displayLaterals = constraints.maxWidth > maxHeaderWidth + 2 * 300;
        final headerRounded = constraints.minWidth >= maxHeaderWidth;
        final client = Matrix.of(context).client;

        final header = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxHeaderWidth),
          child: Padding(
            padding: headerRounded && displayChat
                ? const EdgeInsets.all(8.0)
                : EdgeInsets.zero,
            child: FutureBuilder<String?>(future: () async {
              var uri = await room?.avatar?.getThumbnailUri(client,
                  width: 1000, height: 800, method: ThumbnailMethod.scale);
              return uri.toString();
            }(), builder: (context, snapshot) {
              final roomUrl = snapshot.data;

              return Container(
                height: headerHeight,
                decoration: BoxDecoration(
                  borderRadius:
                      !headerRounded ? null : BorderRadius.circular(8),
                  image: roomUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(roomUrl, headers: {
                            "authorization": "Bearer ${client.accessToken}"
                          }),
                          fit: BoxFit.cover)
                      : null,
                  gradient:
                      roomUrl != null ? null : noImageBoxDecoration(context),
                ),
                child: Column(
                  children: [
                    if (headerChildBuilder != null)
                      headerChildBuilder!(displaySideBar: displaySideBar),
                  ],
                ),
              );
            }),
          ),
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leftBar != null && displayLaterals)
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Card(
                    margin: EdgeInsets.zero,
                    child: SizedBox(width: 300, child: leftBar!)),
              ),
            Expanded(
              child: ListView(controller: controller, children: [
                header,
                const SizedBox(
                  height: 10,
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxHeaderWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (displaySideBar)
                          SizedBox(
                              width: sidebarWidth,
                              child: sidebarBuilder!(
                                  displayLeftBar: displayLaterals)),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: mainWidth),
                                child: mainBuilder(
                                    displaySideBar: displaySideBar,
                                    displayLeftBar: displayLaterals)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
            if (rightBar != null && displayLaterals)
              SizedBox(width: 400, child: rightBar!),
            if (displayChat)
              SizedBox(
                  width: 400,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RoomChatCard(room: room!),
                  ))
          ],
        );
      }),
    );
  }
}

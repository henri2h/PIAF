import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix/partials/components/layouts/custom_header.dart';

import '../chat/room_chat_card.dart';

class LayoutView extends StatelessWidget {
  const LayoutView(
      {Key? key,
      this.controller,
      required this.customHeader,
      required this.mainBuilder,
      this.sidebarBuilder,
      this.leftBar,
      required this.headerChildBuilder,
      this.maxSidebarWidth = 1000,
      this.maxChatWidth = 1400,
      this.sidebarWidth = 300,
      this.mainWidth = 600,
      this.headerHeight,
      this.displayChat = true,
      this.maxHeaderWidth = 1200,
      this.room})
      : super(key: key);

  final Widget? leftBar;
  final Widget Function({required bool displayLeftBar})? sidebarBuilder;
  final Widget Function(
      {required bool displaySideBar, required bool displayLeftBar}) mainBuilder;
  final Widget Function({required bool displaySideBar}) headerChildBuilder;

  final Room? room;

  final double maxSidebarWidth;

  final bool displayChat;
  final double maxChatWidth;

  final double sidebarWidth;
  final double mainWidth;
  final CustomHeader customHeader;
  final ScrollController? controller;

  final double? headerHeight;
  final double maxHeaderWidth;

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
    String? roomUrl = room?.avatar
        ?.getThumbnail(room!.client,
            width: 1000, height: 800, method: ThumbnailMethod.scale)
        .toString();

    return LayoutBuilder(builder: (context, constraints) {
      final displaySideBar =
          constraints.maxWidth >= maxSidebarWidth && sidebarBuilder != null;
      final displayChat = constraints.maxWidth >= maxChatWidth &&
          this.displayChat &&
          room != null;

      final displayLeftBar = constraints.maxWidth > maxHeaderWidth + 2 * 300;
      final headerRounded = constraints.minWidth >= maxHeaderWidth;

      final header = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxHeaderWidth),
        child: Padding(
          padding: headerRounded && displayChat
              ? const EdgeInsets.all(8.0)
              : EdgeInsets.zero,
          child: Container(
            height: headerHeight,
            decoration: BoxDecoration(
              borderRadius: !headerRounded ? null : BorderRadius.circular(8),
              image: roomUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(roomUrl),
                      fit: BoxFit.cover)
                  : null,
              gradient: roomUrl != null ? null : noImageBoxDecoration(context),
            ),
            child: Column(
              children: [
                customHeader,
                headerChildBuilder(displaySideBar: displaySideBar),
              ],
            ),
          ),
        ),
      );

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ListView(controller: controller, children: [
              Center(
                  child: displayLeftBar
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (leftBar != null)
                              SizedBox(width: 300, child: leftBar!),
                            header,
                            if (leftBar != null)
                              const SizedBox(
                                width: 300,
                              )
                          ],
                        )
                      : header),
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
                        Card(
                            child: SizedBox(
                                width: sidebarWidth,
                                child: sidebarBuilder!(
                                    displayLeftBar: displayLeftBar))),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: mainWidth),
                              child: mainBuilder(
                                  displaySideBar: displaySideBar,
                                  displayLeftBar: displayLeftBar)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          if (displayChat)
            SizedBox(
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RoomChatCard(room: room!),
                ))
        ],
      );
    });
  }
}

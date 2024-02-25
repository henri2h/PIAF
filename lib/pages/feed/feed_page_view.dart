import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/models/search/search_mode.dart';
import 'package:piaf/utils/minestrix/minestrix_community_extension.dart';
import 'package:piaf/chat/partials/custom_list_view.dart';
import 'package:piaf/chat/partials/sync/sync_status_card.dart';
import 'package:piaf/chat/utils/matrix_widget.dart';

import '../../partials/account_selection_button.dart';
import '../../partials/components/layouts/layout_view.dart';
import '../../partials/components/minestrix/minestrix_title.dart';
import '../../partials/home/onboarding_widget.dart';
import '../../partials/room_feed_tile_navigator.dart';
import '../../partials/app_title.dart';
import '../../partials/navigation/rightbar.dart';
import '../../partials/post/post.dart';
import '../../router.gr.dart';
import 'feed_page.dart';

class FeedPageView extends StatelessWidget {
  final FeedPageController controller;
  const FeedPageView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () => controller.launchCreatePostModal(context),
          child: const Icon(Icons.edit)),
      appBar: AppBar(title: const Text("Feed"), actions: [
        IconButton(
            onPressed: () async => await context.navigateTo(
                SearchRoute(initialSearchMode: SearchMode.publicRoom)),
            icon: const Icon(Icons.explore)),
        IconButton(
            onPressed: () async => await context.navigateTo(SearchRoute()),
            icon: const Icon(Icons.search)),
        const AccountSelectionButton()
      ]),
      body: StreamBuilder<Object>(
          stream: Matrix.of(context).onClientChange.stream,
          builder: (context, snapshot) {
            Client? client = Matrix.of(context).client;

            if (client.userID != controller.clientUserId) {
              controller.resetPage();
            }

            return StreamBuilder<int>(
                stream: controller.syncIdStream.stream,
                builder: (context, snap) {
                  return RefreshIndicator(
                    onRefresh: controller.onRefresh,
                    child: LayoutView(
                        leftBar: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const H2Title("Communities"),
                            for (final community in client.getCommunities())
                              RoomFeedTileNavigator(room: community.space),
                          ],
                        ),
                        rightBar: const RightBar(),
                        mainBuilder: (
                                {required bool displaySideBar,
                                required bool displayLeftBar}) =>
                            controller.events?.isNotEmpty != true
                                ? Column(
                                    children: [
                                      FutureBuilder(
                                          future: controller
                                              .roomsLoadingTest(context),
                                          builder: (context, snap) {
                                            if (!snap.hasData) {
                                              return const CircularProgressIndicator();
                                            }
                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                ListView(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  children: [
                                                    client.prevBatch == null
                                                        ? Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const AppTitle(),
                                                              SyncStatusCard(
                                                                  client:
                                                                      client),
                                                            ],
                                                          )
                                                        : Card(
                                                            child:
                                                                OnboardingWidget(
                                                                    client:
                                                                        client),
                                                          ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          }),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      CustomListViewWithEmoji(
                                          itemCount: controller.events!.length,
                                          controller: controller.controller,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemBuilder: (BuildContext c,
                                              int i,
                                              void Function(Offset, Event)
                                                  onReact) {
                                            return Post(
                                                event: controller.events![i],
                                                key: Key(controller
                                                        .events![i].eventId +
                                                    controller.events![i].status
                                                        .toString()),
                                                onReact: (Offset e) => onReact(
                                                    e, controller.events![i]));
                                          }),
                                    ],
                                  )),
                  );
                });
          }),
    );
  }
}
